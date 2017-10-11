local synth = {}

synth.__index = synth

synth.effect = nil
synth.count = 5

-- init synth system
function synth.load()
  for i = 1, synth.count do
    synth[i] = synth.new()
  end

  love.audio.setEffect('myeffect',
    {type='ringmodulator',
     frequency=5,
     volume=1,
    })
  synth.effect = love.audio.getEffect('myeffect')
  synth.readTiltFunc = fetchReadTiltFunc()
end

function synth.new(a, d, s, r)
  local self = setmetatable({}, synth)
  self.A = a or 0.15 -- attack
  self.D = d or 0.10 -- decay
  self.S = s or 0.65 -- sustain
  self.R = r or 0.55 -- release
  self.noteOn = nil
  self.noteOff = nil
  local sample_path = 'samples/brite.wav'
  self.sample = love.audio.newSource(love.sound.newDecoder(sample_path))
  self.sample:setLooping(true)
  self.sample:setVolume(0)
  self.sample:setEffect('myeffect')
  self.sample:play()
  return self
end

function fetchReadTiltFunc()
-- finding acc
local func
  local joysticks = love.joystick.getJoysticks()
  for i, joystick in ipairs(joysticks) do
    if joystick:getName() == 'Android Accelerometer' then
      func = function() return joystick:getAxis(2) end
      break
    end
  end
  func = func or function() return 0 end
  return func
end

function synth:startNote(pitch)
  self.noteOn = 0
  self.noteOff = nil
  self.sample:setPitch(pitch)
end

function synth:stopNote()
  self.noteOff = self.noteOn
end

-- https://www.desmos.com/calculator/wp88j1ojhu
function synth:adsr()
  local vol = 0
  local state = 'mute'
  --if self.NoteOff then
  --  if self.NoteOff > self.R then -- mute
  --    vol = 0
  --    self.noteOn = nil
  --    self.noteOff = nil
  --    state = 'mute'
  --  else -- release
  --    vol = (self.R - self.NoteOff) / self.R
  --    state = 'release'
  --  end
  --elseif self.noteOn and self.noteOn > self.A then -- decay and sustain
  --  vol = math.max(self.S, 1 - (1 - self.S) * (self.D - self.noteOn + self.A) / self.D)
  --  state = 'decay/sustain'
  --elseif self.noteOn then -- attack
  --  vol = 1 - (self.A - self.noteOn) / self.A
  --  state = 'attack'
  --end

  if not self.noteOn then return 0, 'mute' end

  local A = self.noteOn / self.A
  local D = (self.S - 1) / self.D * (self.noteOn - self.A) + 1
  local S = self.S
  local O = self.noteOff and self.noteOff or 15
  local R = -self.S / self.R * (self.noteOn - O) + self.S
  vol = math.max(math.min(A, math.max(D, math.min(S, R))), 0)

  state = (self.noteOn and 'On' or '__') .. (self.noteOff and 'Off' or '___')

  return vol, state
end

function synth.update(dt)
  for i,s in ipairs(synth) do
    s.noteOn = s.noteOn and s.noteOn + dt or nil
    s.sample:setVolume(s:adsr()) -- update volume according to ADSR envelope
  end
  synth.effect.frequency = 10 * (1 - synth.readTiltFunc())
  love.audio.setEffect('myeffect', synth.effect)
end

-- get synth that's not playing, or has longest note duration (preferably already released note)
function synth.get_unused()
  local synths_sorted = {}
  for i = 1, synth.count do synths_sorted[i] = synth[i] end
  table.sort(synths_sorted, function(a, b)
    ac = (a.noteOn or math.huge) + (a.noteOff and 15 or 0)
    bc = (b.noteOn or math.huge) + (b.noteOff and 15 or 0)
    return ac > bc
    end)
  return synths_sorted[1]
end

return synth