sampler = {}
sampler.__index = sampler

local efx = require('efx')

local samples = {}

function sampler.new(settings)
  local self = setmetatable({}, sampler)

  self.synths = {} -- collection of sources in a map
  local synthCount  = settings.synthCount or 6
  local path        = settings.path

  self.looped       = settings.looped or false
  self.masterVolume = 1

  self.envelope = settings.envelope or { attack  = 0,
                                         decay   = 0,
                                         sustain = 1,
                                         release = 0.35 }

  -- prepare samples that will be used by synths
  for i,sample in ipairs(settings) do
    local decoder = love.sound.newDecoder(sample.path)
    sample.soundData = love.sound.newSoundData(decoder)
    sample.transpose = sample.transpose or 0
    sample.velocity  = sample.velocity or 0.8
    table.insert(samples, sample)
  end

  -- initialize synths
  for i=1, synthCount do
    self.synths[i] = {
      source = nil,
      volume = 0,
      active = false,
      duration = math.huge,
      enveloped = 0,
    }
  end
  return self
end

function sampler:update(dt, touches)
  -- update sources for existing touches
  for i, synth in ipairs(self.synths) do
    local touch = touches[synth.touchId]

    if touch and touch.note then           -- update existing notes
      local pitch = self:noteToPitch(touch.note, synth.transpose)
      synth.source:setPitch(pitch)
    else
      synth.active = false                 -- not pressed, let envelope release
    end
    synth.enveloped = self:applyEnvelope(dt, synth.enveloped, synth.active, synth.duration)
    local volume = synth.enveloped * self.masterVolume
    if synth.source then
      synth.source:setVolume(volume)
    end
    if touches[synth.touchId] then
      touches[synth.touchId].volume = volume
    end
    synth.duration = synth.duration + dt
  end
  -- hunt for new touches and play them
  for id, touch in pairs(touches) do
    if touch.noteRetrigger then
      self:assignSynth(id, touch)
    end
  end
end

function sampler:noteToPitch(note, transpose)
  -- equal temperament
  return math.pow(math.pow(2, 1/12), note + transpose)
end

function sampler:assignSynth(touchId, touch)
  -- find synth with longest duration
  maxDuration = -100
  selected = nil
  for i, synth in ipairs(self.synths) do
    if synth.duration > maxDuration + (synth.active and 10 or 0) then
      maxDuration = synth.duration
      selected = i
    end
  end
  -- move source to correct key
  local synth = self.synths[selected]
  -- init and play
  if synth.source then
    synth.source:stop()
  end
  local sample = self:assignSample(touch.note, touch.pressure or 1)
  synth.source = love.audio.newSource(sample.soundData)
  synth.touchId = touchId
  synth.duration = 0
  synth.enveloped = 0
  synth.active = true
  synth.transpose = sample.transpose
  efx.applyFilter(synth.source)
  synth.source:setPosition(touch.qr[1]/4, touch.qr[2]/4, 0.5)
  synth.source:setLooping(self.looped)
  synth.source:play()
  return synth
end

function sampler:assignSample(note, velocity)
  local bestFitness = math.huge
  local selected = nil
  for i, sample in ipairs(samples) do
    local fitness = math.abs(-sample.transpose - note) + math.abs(sample.velocity - velocity)
    if fitness < bestFitness then
      selected = i
      bestFitness = fitness
    end
  end
  return samples[selected]
end

function sampler:applyEnvelope(dt, vol, active, duration)
  if active then
    if self.envelope.attack == 0 and duration < 0.01 then             -- flat
      return self.envelope.sustain
    elseif duration < self.envelope.attack then                       -- attack
      return vol + 1 / self.envelope.attack * dt
    elseif duration < self.envelope.attack + self.envelope.decay then -- decay
      return vol - (1 - self.envelope.sustain) / self.envelope.decay * dt
    else                                                              -- sustain
      return vol
    end
  else                                                                -- release
    return math.max(0, vol - self.envelope.sustain / self.envelope.release * dt)
  end
end

return sampler