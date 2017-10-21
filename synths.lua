local synths = {}

local controls = require('controls')

synths.__index = synths

synths.count = 6

-- init synth system
function synths.load(preset)
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
    if synths[i] then
      synths[i].sample:stop()
    end
    synths[i] = synths.new(preset)
  end
end

function synths.new(preset)
  print(preset)
  local self = setmetatable({}, synths)
  self.envelope = preset.envelope
  self.slopes = {
    A = 1 / self.envelope.A,
    D = -(1 - self.envelope.S) / self.envelope.D,
    R = - self.envelope.S / self.envelope.R,
  }
  self.pad = nil
  self.duration = nil -- note on duration, nil if not pressed
  self.volume = 0

  local sample_path = preset.samples['C'] -- TODO: multiple samples across octaves
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
    return math.max(self.volume + self.slopes.R * dt, 0)            -- R
  end -- the rest of function is else case

  if self.duration < self.envelope.A then
    return self.volume + self.slopes.A * dt                         -- A
  elseif self.duration < self.envelope.A + self.envelope.D then
    return self.volume + self.slopes.D * dt                         -- D
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
  synths.modulation.frequency = 3 * remap_clamp(0.8, -1, 0, 10, controls.tilt[2])
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

function remap(minA, maxA, minB, maxB, amount)
  return minB + (amount - minA) * (maxB - minB) / (maxA - minA)
end

function remap_clamp(minA, maxA, minB, maxB, amount)
  return math.max(minB, math.min(maxB, minB + (amount - minA) * (maxB - minB) / (maxA - minA)))
end

return synths