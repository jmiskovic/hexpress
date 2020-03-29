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

states = {
  off = {},
  armed = {},
  recording = {},
  playing = {}
}

-- global for all tapes
recorder.state = states.armed
recorder.length = 0
recorder.speed = 1
recorder.time = 0
recorder.timePrev = -1
recorder.tapes = {}
recorder.currentPatch = nil -- patch is preloaded here so it can be quickly transfered to tape

function recorder.addTape()
  local self = setmetatable({}, tape)
  -- tape properties
  self.content = {} -- the actual recording of notes, array of {time, stream} tables
  self.startTime = 0 -- time at which the used part of tape
  self.endTime = 0 -- end of used part of tape
  self.placement = {-1.65 + 0.35 * #recorder.tapes, -0.88} -- on-screen location
  self.dragging = false -- being dragged around the screen
  self.recording = false -- currently recording
  self.doneRecording = false -- recording just stopped, needs processing
  self.touchId = nil -- last touch id, to distinguish new touch from held touch
  self.patch = nil -- a copy of patch is instantiated just for tape playback
  self.headOnNote = false -- note being recorded or played currently
  self.canvas = love.graphics.newCanvas(200, 200) -- tape visualization
  self:drawVinyl()
  table.insert(recorder.tapes, self)
  return self
end


function recorder.patchChanged(patch)
  if recorder.state ~= states.off then
    recorder.currentPatch = patch.load()
  end
end


function recorder.interpret(s, inSelector)
  for i,tape in ipairs(recorder.tapes) do
    tape.doneRecording = false -- clean info from previous frame
    tape:interpret(s, inSelector)
  end

  if recorder.tapes[1] and recorder.tapes[1].recording and recorder.state ~= states.recording then
    recorder.state = states.recording
    recorder.time = 0
  end
  if recorder.tapes[1] and recorder.tapes[1].doneRecording then
    recorder.state = states.playing
    recorder.length = recorder.tapes[1].endTime
  end

  --[[ on recorder
  if y - self.placement[2] > 0 then
    recorder.speed = recorder.speed * 0.998
  else
    recorder.speed = recorder.speed * 1.002
  end
  --]]
end


function recorder.process(s)
  for i,tape in ipairs(recorder.tapes) do
    tape:process(s)
  end

  if recorder.state == states.recording or recorder.state == states.playing then
    recorder.time = recorder.time + s.dt * recorder.speed
  end
  if recorder.state == states.playing then
    recorder.time = recorder.time % recorder.length -- loop tape back to start
  end
  recorder.timePrev = recorder.time - s.dt * recorder.speed
  track("%1.2f", recorder.time)
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
    if (x - self.placement[1])^2 + (y - self.placement[2])^2 < 0.03 then
      if not inSelector then
        -- on new touch toggle recording
        if id ~= self.touchId then
          if not self.recording then -- start recording
            self.patch = recorder.currentPatch
            self.recording = true
            self.content = {}
          else -- stop recording
            self.recording = false
            self.doneRecording = true
            self.endTime = recorder.time
            self.patch.sampler.masterVolume = 0.5
          end
          self.touchId = id
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
  local next = next
  if self.recording then -- tape recording
    table.insert(self.content, {recorder.time, s})
    self.headOnNote = next(s.touches) ~= nil
  elseif self.doneRecording then -- tape post-processing
    print('recorded', recorder.length, 'seconds of sweet sweet music')
  end
  if not self.recording and self.patch then -- tape playback
    for i, rec in ipairs(self.content) do
      local noteTime, stream = unpack(rec)
      if noteTime < math.max(recorder.time, recorder.timePrev) and noteTime > math.min(recorder.time, recorder.timePrev) then
        self.patch.sampler:processTouches(s.dt / recorder.length, stream.touches)
        self.headOnNote = next(stream.touches) ~= nil
      end
    end
  end
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
  for i, rec in ipairs(self.content) do
    noteTime, stream = unpack(rec)
    for id, touch in pairs(stream.touches) do
      if touch.note and noteTime < recorder.length then
        local angle = 2 * math.pi * noteTime / recorder.length
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
  if self.doneRecording then
    love.graphics.push()
    self:drawVinyl()
    self:drawNotes()
    love.graphics.pop()
  end
  -- vinyl record
  love.graphics.push()
  love.graphics.translate(unpack(self.placement))  
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
    love.graphics.rotate(-2 * math.pi * recorder.time / recorder.length)
    love.graphics.draw(self.canvas, -100, -100)
    love.graphics.setBlendMode("alpha")
    love.graphics.pop()
  end
  -- playing head
  love.graphics.setColor(colorScheme.background)
  love.graphics.arc('fill', 0.05, 0, 0.065, math.pi * 1/12, -math.pi * 1/12)
  love.graphics.setColor(self.headOnNote and colorScheme.note or colorScheme.head)
  love.graphics.arc('fill', 0.06, 0, 0.05, math.pi * 1/12, -math.pi * 1/12)
  love.graphics.pop()
end


return recorder