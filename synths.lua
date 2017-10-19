local synths = {}

synths.__index = synths

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
  synths.modulation = love.audio.getEffect('modulation')
  for i = 1, synths.count do
    synths[i] = synths.new()
  end
  synths.readTilt = fetchReadTiltFunc()
end

function synths.new(a, d, s, r)
  local self = setmetatable({}, synths)
  self.envelope = {
    A = a or 0.45, -- attack
    D = d or 0.20, -- decay
    S = s or 0.85, -- sustain
    R = r or 0.35, -- release
  }
  self.slope = {
    A = 1 / self.envelope.A,
    D = -(1 - self.envelope.S) / self.envelope.D,
    R = - self.envelope.S / self.envelope.R,
  }
  self.pad = nil
  self.duration = nil -- note on duration, nil if not pressed
  self.volume = 0
  local sample_path = 'samples/brite48000.wav'
  self.sample = love.audio.newSource(love.sound.newDecoder(sample_path))
  self.sample:setLooping(true)
  self.sample:setVolume(self.volume)
  self.sample:setEffect('modulation')
  self.sample:setEffect('reverb')
  return self
end

function synths:startNote(pitch)
  self.duration = 0
  self.volume = 0 --reset any leftover envelope from last note
  self.sample:setPitch(pitch)
  -- map note pitch to physical location (stereo pan)
  self.sample:setPosition(remap(0, 3, -1, 1, pitch), 0, 2.5)
  self.sample:stop()
  self.sample:play()
  return s
end

function synths:stopNote()
  self.duration = nil
end

-- https://www.desmos.com/calculator/wp88j1ojhu
function synths:adsr(dt)
  if not self.duration then
    return math.max(self.volume + self.slope.R * dt, 0)            -- R
  end -- the rest of function is else case

  if self.duration < self.envelope.A then
    return self.volume + self.slope.A * dt                         -- A
  elseif self.duration < self.envelope.A + self.envelope.D then
    return self.volume + self.slope.D * dt                         -- D
  else
    return self.volume                                             -- S
  end
end

function synths.update(dt)
  for i,s in ipairs(synths) do
    s.duration = s.duration and s.duration + dt or nil
    s.volume = s:adsr(dt) -- update volume according to ADSR envelope
    s.sample:setVolume(math.max(0, math.min(1, s.volume)))
  end
  local tilt = {synths.readTilt()}
  synths.modulation.frequency = 3 * remap_clamp(0.8, -1, 0, 10, tilt[2])
  love.audio.setEffect('modulation', synths.modulation)
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

function fetchReadTiltFunc()
-- finding acc
local func
  local joysticks = love.joystick.getJoysticks()
  for i, joystick in ipairs(joysticks) do
    if joystick:getName() == 'Android Accelerometer' then
      func = function() return joystick:getAxis(1), joystick:getAxis(2), joystick:getAxis(3) end
      break
    end
  end
  func = func or function() return 0,0,0 end
  return func
end

function remap(minA, maxA, minB, maxB, amount)
  return minB + (amount - minA) * (maxB - minB) / (maxA - minA)
end

function remap_clamp(minA, maxA, minB, maxB, amount)
  return math.max(minB, math.min(maxB, minB + (amount - minA) * (maxB - minB) / (maxA - minA)))
end

return synths