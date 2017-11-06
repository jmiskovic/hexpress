local synths = {}

local controls = require('controls')

synths.__index = synths

synths.count = 6

synths.effects = {
  {
    type='ringmodulator',
    volume=1.0,
    frequency=5,
  },
  {
    type='reverb',
    volume=0.3,
    gain=0.8,
    density=0.7,
    diffusion=0.5,
    decayhighratio=0.8,
  },
}

synths.filters = {
  {
    type='lowpass',
    volume=0.3,
    highgain=1.0,
  },
}

function synths.update_effects(dt)
  synths.effects[1].volume    = remap_clamp(controls.tilt[2], -0.4, 0.3, 0, 1)
  synths.effects[1].frequency = remap_clamp(controls.tilt[1], -0.3, 0.3, 0, 15)
  synths.effects[2].volume    = remap_clamp(controls.tilt[2],  1, 0.6, 0, 0.3)
  synths.effects[2].highgain  = remap_clamp(controls.tilt[2], -1, 0.8, 0, 1)
  synths.effects[2].decaytime = remap_clamp(controls.tilt[2], 0.8, -1, 2, 20)
  local A = remap_clamp(controls.tilt[2], 0.5, -1, 0, 5)
  local slopeA = 1 / A
  for _,s in ipairs(synths) do
    s.envelope.A = A
    s.slopes.A = slopeA
  end

  love.audio.setEffect(synths.effects[1].type, synths.effects[1])
  love.audio.setEffect(synths.effects[2].type, synths.effects[2])
end

-- init synth system
function synths.load(preset)
  --log('Synth %s', preset.samples.C)
  synths.update_effects(0.03)

  -- initialize effects
  for _,e in ipairs(synths.effects) do
    love.audio.setEffect(e.type, e)
  end
  -- initialize synths
  for i = 1, synths.count do
    if synths[i] then
      synths[i].sample:stop()
    end
    synths[i] = synths.new(preset)
    -- apply effects to synths
    for _,e in ipairs(synths.effects) do
      synths[i].sample:setEffect(e.type)
    end
  end
end

function synths.new(preset)
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
  self.sample:setLooping(preset.looping or false)
  self.sample:setVolume(self.volume)
  self.sample:setFilter(synths.filters[1])
  return self
end

function synths:startNote(pitch)
  self.duration = 0
  self.volume = 0 --reset any leftover envelope from last note
  self.sample:setPitch(pitch)
  -- map note pitch to physical location (stereo pan)
  self.sample:setPosition(remap(pitch, 0, 3, -1, 1), 0, 0.5)
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

  if self.envelope.A == 0 and self.duration == 0 then
    return self.envelope.S
  elseif self.duration < self.envelope.A then
    return self.volume + self.slopes.A * dt                         -- A
  elseif self.duration < self.envelope.A + self.envelope.D then
    return self.volume + self.slopes.D * dt                         -- D
  else
    return self.volume                                              -- S
  end
end

function synths.update(dt)
  synths.update_effects(dt)
  for i,s in ipairs(synths) do
    s.volume = s:adsr(dt) -- update volume according to ADSR envelope
    s.volume = math.max(0, math.min(1, s.volume))
    s.duration = s.duration and s.duration + dt or nil
    s.sample:setVolume(s.volume)
  end
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

function remap(amount, minA, maxA, minB, maxB)
  return minB + (amount - minA) * (maxB - minB) / (maxA - minA)
end

function remap_clamp(amount, minA, maxA, minB, maxB)
  return math.max(minB, math.min(maxB, minB + (amount - minA) * (maxB - minB) / (maxA - minA)))
end

return synths