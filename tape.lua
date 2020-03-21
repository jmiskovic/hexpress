local tape = {}
tape.__index = tape

local l = require('lume')

local colorScheme = {
  recording  = {l.hsl(0, 0.6, 0.4)},
  background = {l.hsl(0, 0, 0.1)},
  grooves    = {l.hsl(0, 0, 0.15)},
  head       = {l.hsl(0, 0.3, 0.5)},
  spindle    = {l.hsl(0, 0, 0.6)},
  note       = {l.hsl(0, 0.6, 0.4)},
}

--[[
TODO:
  per-tape volume: low mid high
  changing tempo
  syncing between length multiples (4 bars against 1 bar)
  track icon pressing doesn't play note
  adjustable track icon position (on main screen)
  saving and loading to storage
  more than 2 tracks, adding and removing
]]

function tape.create()
  local self = setmetatable({}, tape)
  self.position = {-1.5, -0.85}
  self.recording = false
  self.notes = {}
  self.touchId = nil
  self.patch = nil
  self.time = 0
  self.timePrev = 0
  self.length = math.huge -- huge!
  self.lastPlayed = -1
  self.recordingStop = false
  self.canvas = love.graphics.newCanvas(200, 200)
  return self
end


function tape:startStop(s)
    -- record start / stop
  local cnt = 0
  for id,touch in pairs(s.touches) do
    cnt = cnt + 1
    local x, y = love.graphics.inverseTransformPoint(touch[1], touch[2])
    if (self.position[1] - x)^2 + (self.position[2] - y)^2 < 0.03 then
      -- on new touch toggle recording
      if id ~= self.touchId then
        if not self.recording then
          self.patch = self.loadedPatch
          self.recording = true
          self.time = 0
          self.notes = {}
        else
          self.recording = false
          self.recordingStop = true
          self.length = self.time
          self.masterVolume = 0.5
        end
        self.touchId = id -- mark id to know if it is held touch of new touch
      end
    end
  end
  if cnt == 0 then
    self.touchId = nil
  end
end


function tape:process(s, patch)
  self:startStop(s)
  -- tape recording
  if self.recording then
    table.insert(self.notes, {self.time, s})
    self.time = self.time + s.dt
  end
  -- tape playback
  if not self.recording and #self.notes > 0 and self.patch then
    for i, rec in ipairs(self.notes) do
      local noteTime, stream = unpack(rec)
      if noteTime < math.max(self.time, self.timePrev) and noteTime > math.min(self.time, self.timePrev) then
        self.patch.sampler:processTouches(s.dt, stream.touches)
      end
    end
    -- loop tape back to start
    if self.time > self.length then
      self.time = 0
    end
    self.timePrev = self.time
    self.time = self.time + s.dt
  end
end


function tape:drawNotes()
  love.graphics.origin()
  love.graphics.setCanvas(self.canvas)
  love.graphics.clear()
  love.graphics.setBlendMode("alpha")
  love.graphics.translate(100,100)
  love.graphics.scale(100)
  -- grooves
  love.graphics.setColor(colorScheme.grooves)
  local grooveCount = 7
  for i = 1, grooveCount, 1 do
    love.graphics.setLineWidth(0.04)
    love.graphics.circle('line', 0, 0, l.remap(i, 1, grooveCount, 0.4, 0.85))
  end
  -- notes
  love.graphics.setColor(colorScheme.note)
  love.graphics.setLineWidth(0.08)
  love.graphics.line(0.5, 0, 0.7, 0)
  for i, rec in ipairs(self.notes) do
    noteTime, stream = unpack(rec)
    for id, touch in pairs(stream.touches) do
      if touch.note and noteTime < self.length then
        local angle = 2 * math.pi * noteTime / self.length
        love.graphics.push()
        love.graphics.rotate(angle)
        love.graphics.translate(0.6 + touch.note * 0.01, 0)
        love.graphics.circle("fill", 0, 0, 0.05)
        love.graphics.pop()
      end
    end
  end
  -- center spindle
  love.graphics.setColor(colorScheme.spindle)
  love.graphics.circle("fill", 0, 0, 0.03)

  love.graphics.setCanvas()
end


function tape:draw()
  -- when recording stops, map recorded notes onto circle
  if self.recordingStop then
    love.graphics.push()
    self:drawNotes()
    self.recordingStop = false
    love.graphics.pop()
  end
  -- vinyl record
  love.graphics.push()
  love.graphics.translate(unpack(self.position))
  love.graphics.setColor(colorScheme.background)
  love.graphics.circle("fill", 0, 0, 0.1)
  if self.recording then
    love.graphics.setColor(colorScheme.recording)
    love.graphics.circle("fill", 0, 0, 0.085)
  else
    -- recorded notes
    love.graphics.push()
    love.graphics.setColor(1,1,1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.scale(1/1000)
    love.graphics.rotate(-2 * math.pi * self.time / self.length)
    love.graphics.draw(self.canvas, -100, -100)
    love.graphics.setBlendMode("alpha")
    love.graphics.pop()
  end
  -- playing head
  love.graphics.setColor(colorScheme.background)
  love.graphics.arc('fill', 0.05, 0, 0.065, math.pi * 1/12, -math.pi * 1/12)
  love.graphics.setColor(colorScheme.head)
  --love.graphics.rectangle('fill', 0.07, -0.013, 0.05, 0.028, 0.02, 0.02)
  love.graphics.arc('fill', 0.06, 0, 0.05, math.pi * 1/12, -math.pi * 1/12)
  love.graphics.pop()
end


function tape:patchChanged(patch)
  self.loadedPatch = patch.load()
end


return tape