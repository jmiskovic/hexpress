local recorder = {}
local tape = {}
tape.__index = tape

local l = require('lume')

local colorScheme = {
  recording  = {l.hsl(0, 0.6, 0.4)},
  background = {l.hsl(0, 0, 0.1)},
  grooves    = {l.hsl(0, 0, 0.15)},
  head       = {l.hsl(0, 0.3, 0.5)},
  spindle    = {l.hsl(0, 0.1, 0.3)},
  note       = {l.hsl(0, 0.6, 0.4)},
}

-- global for all tapes
recorder.speed = 1
recorder.time = 0
recorder.tapes = {}
recorder.loadedPatch = nil

--[[
TODO:
  per-tape volume: low mid high
  changing tempo
  syncing between length multiples (4 bars against 1 bar)
  adding echo track with dotted eighth delay
  adjustable track icon position (on main screen)
  saving and loading to storage
  more than 2 tracks, adding and removing
]]

function recorder.addTape()
  local self = setmetatable({}, tape)
  self.position = {-1.5, -0.85}
  self.recording = false
  self.notes = {}
  self.touchId = nil
  self.patch = nil -- a copy of patch is instantiated just for tape playback
  self.time = 0
  self.timePrev = 0
  self.length = math.huge -- huge!
  self.recordingStop = false
  self.canvas = love.graphics.newCanvas(200, 200)
  self:drawVinyl()
  table.insert(recorder.tapes, self)
  return self
end

function recorder.patchChanged(patch)
  recorder.loadedPatch = patch.load()
end

function recorder.interpret(s, inSelector)
  for i,tape in ipairs(recorder.tapes) do
    tape:interpret(s, inSelector)
  end
end


function recorder.process(s)
  for i,tape in ipairs(recorder.tapes) do
    tape:process(s)
  end
end


function recorder.draw()
  for i,tape in ipairs(recorder.tapes) do
    tape:draw()
  end
end


-- tape functions --


function tape:interpret(s, inSelector)
  local cnt = 0
  for id,touch in pairs(s.touches) do
    cnt = cnt + 1
    local x, y = love.graphics.inverseTransformPoint(touch[1], touch[2])
    if (x - self.position[1])^2 + (y - self.position[2])^2 < 0.03 then
      if inSelector then
        if y - self.position[2] > 0 then
          recorder.speed = recorder.speed * 0.998
        else
          recorder.speed = recorder.speed * 1.002
        end
      else -- on new touch toggle recording
        if id ~= self.touchId then
          if not self.recording then
            self.patch = recorder.loadedPatch
            self.recording = true
            self.time = 0
            self.notes = {}
          else
            self.recording = false
            self.recordingStop = true
            self.length = self.time
            self.masterVolume = 0.5
          end
          self.touchId = id -- mark id to distinguish new touch from held touch
        end
      end
      s.touches[id] = nil -- sneakily remove touch from stream to prevent unintended notes
    end
  end
  if cnt == 0 then
    self.touchId = nil
  end
end


function tape:process(s)
  -- tape recording
  if self.recording then
    table.insert(self.notes, {self.time, s})
  end
  -- tape playback
  if not self.recording and #self.notes > 0 and self.patch then
    for i, rec in ipairs(self.notes) do
      local noteTime, stream = unpack(rec)
      if noteTime < math.max(self.time, self.timePrev) and noteTime > math.min(self.time, self.timePrev) then
        self.patch.sampler:processTouches(s.dt, stream.touches)
      end
    end
    self.timePrev = self.time
    -- loop tape back to start
    if self.time > self.length then
      self.time = 0
      self.timePrev = -s.dt
    end
  end
  self.time = self.time + s.dt * recorder.speed
end

function tape:drawVinyl()
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
  -- start marker
  love.graphics.setColor(colorScheme.head)
  love.graphics.setLineWidth(0.06)
  love.graphics.line(0.7, 0, 0.9, 0)
  -- center spindle
  love.graphics.setColor(colorScheme.spindle)
  love.graphics.circle("fill", 0, 0, 0.25)
  love.graphics.setCanvas()
end

function tape:drawNotes()
  love.graphics.origin()
  love.graphics.setCanvas(self.canvas)
  love.graphics.setBlendMode("alpha")
  love.graphics.translate(100,100)
  love.graphics.scale(100)
  love.graphics.setColor(colorScheme.note)
  -- notes
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
  love.graphics.setCanvas()
end


function tape:draw()
  -- when recording stops, map recorded notes onto circle
  if self.recordingStop then
    love.graphics.push()
    self:drawVinyl()
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


return recorder