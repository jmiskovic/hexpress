local synths = {}

local controls = require('controls')

synths.__index = synths

synths.count = 6

synths.effects = {
  {
    type='ringmodulator',
    frequency=5,
    volume=1,
  },
  {
    type='echo',
    feedback=0.2,
    delay=0.05,
    tapdelay=0.08,
    damping=0.3,
    spread=0.5,
    volume=1,
  },
}

-- init synth system
function synths.load(preset)

  local filters = {
  }

  synths.update_effects(0.03)

  for i = 1, synths.count do
    if synths[i] then
      synths[i].sample:stop()
    end
    synths[i] = synths.new(preset)

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
  self.sample:setLooping(true)
  self.sample:setVolume(self.volume)
  return self
end

function synths:startNote(pitch)
  self.duration = 0
  self.volume = 0 --reset any leftover envelope from last note
  self.sample:setPitch(pitch)
  -- map note pitch to physical location (stereo pan)
  self.sample:setPosition(remap(0, 3, 0, 1, pitch), 0, 9.5)
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

function synths.update_effects(dt)
  synths.effects[1].frequency = 3 * remap_clamp(0.8, -1, 0, 10, controls.tilt[2])

  for _,e in ipairs(synths.effects) do
    love.audio.setEffect(e.type, e)
  end
end

function synths.update(dt)
  for i,s in ipairs(synths) do
    s.duration = s.duration and s.duration + dt or nil
    s.volume = s:adsr(dt) -- update volume according to ADSR envelope
    s.sample:setVolume(math.max(0, math.min(1, s.volume)))
  end
  synths.update_effects(dt)
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