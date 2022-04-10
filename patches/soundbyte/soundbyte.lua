local patch = {}
patch.__index = patch

local l = require('lume')
local hexgrid = require('hexgrid')
local sampler = require('sampler')
local fretboard = require('fretboard')
local hexpad = require('hexpad')
local freeform = require('freeform')
local efx = require('efx')

local colorScheme = {
  background    = {l.rgba(0xffb762ff)},
  highlight     = {l.rgba(0xff823bff)},
  surface       = {l.rgba(0xffffe4ff)},
  black         = {l.rgba(0x041528ff)},
  outline       = {l.rgba(0x604b46ff)},
}

-- Possible combination testing
local samplingFrequencies = {48000, 44100, 32000, 22050, 16000, 8000}
local bitDepths = {16, 8}
local bufferSize = 16384
-- on pixel 2 valid combinations are 22050 (8 & 16) and 48000 (8 & 16)

function patch.load()
  local self = setmetatable({}, patch)
  self.hexpad = hexpad.new(false, 0, 3)
  self.fretboard = fretboard.new(false, {-12})
  self.fretboard.neckHeight = 0.25
  self.fretboard.fretWidth  = 0.15

  self.pitchboard = fretboard.new(false, {-48})
  self.pitchboard.neckHeight = 0.2
  self.pitchboard.fretWidth  = 0.04

  patch.triggers = {
    {type='whitekey', note= -12, x=-0.054, y= 0.432, r= 0.132},
    {type='whitekey', note= -10, x= 0.220, y= 0.421, r= 0.132},
    {type='whitekey', note=  -8, x= 0.493, y= 0.447, r= 0.132},
    {type='whitekey', note=  -7, x= 0.769, y= 0.424, r= 0.132},
    {type='whitekey', note=  -5, x= 1.043, y= 0.424, r= 0.132},
    {type='whitekey', note=  -3, x= 1.319, y= 0.415, r= 0.132},
    {type='whitekey', note=  -1, x= 1.596, y= 0.428, r= 0.132},
    {type='blackkey', note= -11, x= 0.059, y= 0.300, r= 0.090},
    {type='blackkey', note=  -9, x= 0.396, y= 0.286, r= 0.090},
    {type='blackkey', note=  -6, x= 0.880, y= 0.274, r= 0.090},
    {type='blackkey', note=  -4, x= 1.193, y= 0.293, r= 0.090},
    {type='blackkey', note=  -2, x= 1.509, y= 0.291, r= 0.090},
    {type='whitekey', note=   0, x=-0.072, y=-0.229, r= 0.132},
    {type='whitekey', note=   2, x= 0.200, y=-0.251, r= 0.132},
    {type='whitekey', note=   4, x= 0.467, y=-0.238, r= 0.132},
    {type='whitekey', note=   5, x= 0.744, y=-0.253, r= 0.132},
    {type='whitekey', note=   7, x= 1.011, y=-0.290, r= 0.132},
    {type='whitekey', note=   9, x= 1.283, y=-0.310, r= 0.132},
    {type='whitekey', note=  11, x= 1.556, y=-0.319, r= 0.132},
    {type='blackkey', note=   1, x= 0.037, y=-0.388, r= 0.090},
    {type='blackkey', note=   3, x= 0.346, y=-0.382, r= 0.090},
    {type='blackkey', note=   6, x= 0.857, y=-0.425, r= 0.090},
    {type='blackkey', note=   8, x= 1.165, y=-0.453, r= 0.090},
    {type='blackkey', note=  10, x= 1.444, y=-0.453, r= 0.090},
  }
  patch.freeform = freeform.new(patch.triggers)

  self.sampler = sampler.new({
    {path='patches/chromakey/sustain.ogg',  note=  0},
    looped = true,
    envelope = { attack = 0.02, decay = 0.40, sustain = 1, release = 0.2 },
  })

  self.efx = efx.load()

  self.button = {
    placement = {-0.25, -0.88},
    pressed = nil,
  }
  local devices = love.audio.getRecordingDevices()
  self.recorder = devices[1]
  self.parameters = self:findRecordingParams()
  self.recording = false        -- currently storing buffers being recorded
  self.recordingLength = 0      -- collected recording length in number of samples
  self.collectedSamples = {}    -- table holding recorded buffers

  self.hexpad.drawCell = function(self, q, r, s, touch)
    love.graphics.scale(touch and 0.8 or 0.75)
    love.graphics.setColor(touch and colorScheme.highlight or colorScheme.surface)
    love.graphics.polygon('fill', hexgrid.roundhex)
    love.graphics.setLineWidth(0.05)
    love.graphics.scale(not touch and 1 or 1 + 0.02 * math.sin(s.time * 50))
    love.graphics.setColor(colorScheme.outline)
    love.graphics.polygon('line', hexgrid.roundhex)
  end
  self.fretboard.colorScheme.neck   = {0, 0, 0, 0}
  self.fretboard.colorScheme.fret   = {0, 0, 0, 0}
  self.fretboard.colorScheme.dot    = {0, 0, 0, 0}
  self.fretboard.colorScheme.shade  = {0, 0, 0, 0}
  self.fretboard.colorScheme.string = colorScheme.background
  self.fretboard.colorScheme.light  = colorScheme.outline
  self.pitchboard.colorScheme.neck   = {0, 0, 0, 0}
  self.pitchboard.colorScheme.fret   = {0, 0, 0, 0}
  self.pitchboard.colorScheme.dot    = {0, 0, 0, 0}
  self.pitchboard.colorScheme.shade  = {0, 0, 0, 0}
  self.pitchboard.colorScheme.string = colorScheme.surface
  self.pitchboard.colorScheme.light  = {0, 0, 0, 0}
  self.freeform.colorScheme.whitekey = colorScheme.surface
  self.freeform.colorScheme.blackkey = colorScheme.black
  love.graphics.setBackgroundColor(colorScheme.background)
  return self
end


function patch:findRecordingParams()
  local success = false -- success locally before you hit it big
  -- test all possible combos
  for _, samplingFrequency in ipairs(samplingFrequencies) do
    for _, bitDepth in ipairs(bitDepths) do
      success = self.recorder:start(bufferSize, samplingFrequency, bitDepth, 1)
      if success then
        return {
          samplingFrequency = samplingFrequency,
          bitDepth = bitDepth
        }
      else
        self.recorder:stop()
      end
    end
  end
  log('Please enable microphone permission')
  return {}
end


local function withFretboard(fun, ...)
  love.graphics.push()
    love.graphics.translate(0, 0.95)
    love.graphics.scale(1, 0.6)
    fun(...)
  love.graphics.pop()
end


local function withPitchboard(fun, ...)
  love.graphics.push()
    love.graphics.translate(0.95, -0.85)
    love.graphics.scale(0.3, 1)
    fun(...)
  love.graphics.pop()
end


local function withHexpad(fun, ...)
  love.graphics.push()
    love.graphics.translate(-1, -0.1)
    love.graphics.scale(0.6)
    fun(...)
  love.graphics.pop()
end


local function waveformInit()
  patch.waveVisualization = {-1, 0}
end


local function waveformAdd(timeFraction, amplitude)
  table.insert(patch.waveVisualization, -1 + 2 * timeFraction)
  table.insert(patch.waveVisualization, math.log(1 + amplitude / 50))
end


local function waveformEnd()
  table.insert(patch.waveVisualization, 1)
  table.insert(patch.waveVisualization, 0)
end


local function waveformDraw()
  if patch.waveVisualization then
    love.graphics.setColor(colorScheme.highlight)
    love.graphics.polygon('line', patch.waveVisualization)
  end
end


function patch:process(s)
  -- while recording constantly collect samples
  if self.recording then
    local data = self.recorder:getData()
    if data then
      self.recordingLength = self.recordingLength + data:getSampleCount()
      table.insert(self.collectedSamples, data)
    end
  end
  -- recording stopped, assemble all collected samples
  if self.button.touchId and not next(s.touches) then
    local crossfadeSamples = math.floor(0.2 * self.parameters.samplingFrequency)
    self.button.touchId = nil
    self.recording = false
    if self.recordingLength > crossfadeSamples * 2 then
      --waveformInit()
      local loopLength = self.recordingLength - crossfadeSamples
      local recording = love.sound.newSoundData(loopLength, self.parameters.samplingFrequency, self.parameters.bitDepth, 1)
      local sampleIndex = 0
      --[[ glue collected samples onto recording, with cross-faded section at beginning
           cross-fade serves to create a seamless loop between track ending and beginning (to eliminate pop)
                       B~~~~~~~~~~~~~E   original recording from beginning to end

                       B~~~~~~~~~E
                                  E~~~   ending section is isolated

                       b<<B~~~~~~E       beginning in faded in
                       E>>e              end is overlapped with beginning and faded out

                       b~~e~~~~~~~       tracks are mixed together in seamless loop                       ]]
      for _, buff in ipairs(self.collectedSamples) do
        for i = 0, buff:getSampleCount() - 1 do
          if sampleIndex < loopLength then
            local sample = buff:getSample(i)
            --print(sampleIndex, loopLength, self.recordingLength)
            recording:setSample(sampleIndex, sample)
            --waveformAdd(sampleIndex / (self.recordingLength - crossfadeSamples), recording:getSample(2sampleIndex))
          else
            local fadein =  l.remap(sampleIndex, loopLength, self.recordingLength, 0, 1, 'clamp')
            local fadeout = l.remap(sampleIndex, loopLength, self.recordingLength, 1, 0, 'clamp')
            local bi = sampleIndex - loopLength
            local beginning = recording:getSample(bi) * fadein
            local ending    =      buff:getSample(i)  * fadeout
            recording:setSample(bi, beginning + ending)
          end
          sampleIndex = sampleIndex + 1
        end
        buff:release()
      end
      self.sampler.samples[1].soundData = recording
      --waveformEnd()
    end
  end
  -- recording start when button is pressed
  for id,touch in pairs(s.touches) do
    local x, y = love.graphics.inverseTransformPoint(touch[1], touch[2])
    if (x - self.button.placement[1])^2 + (y - self.button.placement[2])^2 < 0.03 then
      if not self.button.touchId then
        self.recorder:getData() -- clear data captured so far
        self.recording = true
        self.recordingLength = 0
        self.collectedSamples = {}
      end
      self.button.touchId = id
      s.touches[id] = nil -- sneakily remove touch from stream to prevent unintended notes
    end
  end
  withHexpad(self.hexpad.interpret, self.hexpad, s)
  withFretboard(self.fretboard.interpret, self.fretboard, s)
  withPitchboard(self.pitchboard.interpret, self.pitchboard, s)
  patch.freeform:interpret(s)
  self.efx:process()
  self.sampler:processTouches(s.dt, s.touches, self.efx)
end


function patch.drawMike(time)
  -- stand
  love.graphics.setColor(colorScheme.black)
  love.graphics.rectangle('fill', -0.15, -1.3, 0.3, 0.5)
  -- mike
  love.graphics.setStencilTest("greater", 0)
  local mikeStencil = function()
      love.graphics.setColorMask() -- enable drawing inside stencil function
      love.graphics.setColor(colorScheme.outline)
      love.graphics.rectangle('fill', -0.6, -1, 1.2, 2, 0.4, 0.6)
    end
  love.graphics.stencil(mikeStencil, "replace", 1)
  -- shading
  love.graphics.setColor(colorScheme.surface)
  love.graphics.circle('fill', -2.5, -0.7 + 0.2 * math.sin(time), 2.7)
  -- gills
  for i = -0.6, 0.8, 0.3 do
    love.graphics.setColor(colorScheme.outline)
    love.graphics.rectangle('fill', -0.65, i, 0.53, 0.1, 0.1)
    love.graphics.setColor(colorScheme.black)
    love.graphics.rectangle('fill',  0.25, i, 0.45, 0.1, 0.1)
  end
  -- mount
  love.graphics.setColor(colorScheme.outline)
  love.graphics.push()
  love.graphics.translate(0, -1)
  love.graphics.rotate(math.pi/4)
  love.graphics.rectangle('fill', -0.25, -.25, 0.5, 0.5, 0.2)
  love.graphics.pop()
  love.graphics.setStencilTest() -- disable stencil
end


function patch:draw(s)
  withHexpad(self.hexpad.draw, self.hexpad, s)
  withFretboard(self.fretboard.draw, self.fretboard, s)
  withPitchboard(self.pitchboard.draw, self.pitchboard, s)
  love.graphics.setColor(colorScheme.highlight)
  love.graphics.circle('fill', 0.35, -0.85, 0.05)
  patch.freeform:draw(s)
  --waveformDraw()
  love.graphics.translate(self.button.placement[1], self.button.placement[2])
  love.graphics.scale(0.1)
  self.drawMike(s.time)
  if self.recording then
    love.graphics.push()
    love.graphics.scale(0.03)
    love.graphics.translate(30, -20)
    love.graphics.setFont(hexpad.font)
    love.graphics.setColor(colorScheme.highlight)
    love.graphics.print('REC')
    love.graphics.pop()
  end
end


function patch.icon(time)
  love.graphics.setColor(colorScheme.highlight)
  love.graphics.rectangle('fill', -2, -2, 4, 4)
  love.graphics.scale(0.8 + 0.03 * math.sin(time)^10)
  love.graphics.setColor(colorScheme.background)
  love.graphics.circle('fill', -3, -1 + 0.2 * math.cos(time), 4)
  patch.drawMike(time)
end

--[[
function love.keypressed(key)
  if key == 'tab' then
    freeform.editing = true
    patch.freeform.selected = (patch.freeform.selected % #patch.triggers) + 1
  end
  if key == '`' then
    patch.freeform.selected = ((patch.freeform.selected - 1) % #patch.triggers)
  end
  if key == 'return' then
    for i,v in ipairs(patch.triggers) do
      print(string.format('x=% 1.3f, y=% 1.3f, r=% 1.2f},',v.x, v.y, v.r))
    end
  end
  if key == '=' then
    patch.triggers[patch.freeform.selected].r = patch.triggers[patch.freeform.selected].r * 1.02
  elseif key == '-' then
    patch.triggers[patch.freeform.selected].r = patch.triggers[patch.freeform.selected].r / 1.02
  end
end
--]]

return patch
