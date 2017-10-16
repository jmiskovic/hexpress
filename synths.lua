local synths = {}

synths.__index = synths

synths.effect = nil
synths.count = 6

-- init synth system
function synths.load()
  love.audio.setEffect('reverb',
    {type='reverb',
    })
  love.audio.setEffect('modulation',
    {type='ringmodulator',
     frequency=5,
     volume=1,
    })
  synths.effect = love.audio.getEffect('modulation')
  synths.readTiltFunc = fetchReadTiltFunc()
  for i = 1, synths.count do
    synths[i] = synths.new()
  end
end

function synths.new(a, d, s, r)
  local self = setmetatable({}, synths)
  self.envelope = {
    A = a or 0.45, -- attack
    D = d or 0.20, -- decay
    S = s or 0.85, -- sustain
    R = r or 0.35, -- release
  }
  self.k = {
    R = - self.envelope.S / self.envelope.R,
    A = 1 / self.envelope.A,
    D = -(1 - self.envelope.S) / self.envelope.D,
  }

  self.pad = nil
  self.duration = nil -- note on duration, nil if not pressed
  self.volume = 0
  local sample_path = 'samples/brite.wav'
  self.sample = love.audio.newSource(love.sound.newDecoder(sample_path))
  self.sample:setLooping(true)
  self.sample:setVolume(self.volume)
  self.sample:setEffect('modulation')
  self.sample:setEffect('reverb')
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

function remap(minA, maxA, minB, maxB, amount)
  return minB + (amount - minA) * (maxB - minB) / (maxA - minA)
end

function synths:startNote(pitch)
  self.duration = 0
  self.volume = 0 --reset any leftover envelope from last note
  self.sample:setPitch(pitch)
  -- map note pitch to physical location (stereo pan)
  self.sample:setPosition(remap(0, 3, -1, 1, pitch), 0, 2.5)
  return s
end

function synths:stopNote()
  self.duration = nil
end

-- https://www.desmos.com/calculator/wp88j1ojhu
function synths:adsr(dt)
  if not self.duration then
    return math.max(self.volume + self.k.R * dt, 0)
  end -- the rest of function is else case

  if self.duration < self.envelope.A then
    return self.volume + self.k.A * dt
  elseif self.duration < self.envelope.A + self.envelope.D then
    return self.volume + self.k.D * dt
  else
    return self.volume
  end
end

function synths.update(dt)
  for i,s in ipairs(synths) do
    s.duration = s.duration and s.duration + dt or nil
    s.volume = s:adsr(dt) -- update volume according to ADSR envelope
    s.sample:setVolume(math.max(0, math.min(1, s.volume)))
  end
  synths.effect.frequency = 10 * (1 - synths.readTiltFunc())
  love.audio.setEffect('modulation', synths.effect)
end

-- get synth that's not playing, or has longest note duration (preferably already released note)
function synths.get_unused()
  table.sort(synths, function(a, b)
    -- prefer unused synth with lowest volume,
    -- otherwise select synth that was used the longest
    ac = (a.duration or (500 - a.volume))
    bc = (b.duration or (500 - b.volume))
    return ac > bc
    end)
  return synths[1]
end

return synths