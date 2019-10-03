local sampler = {}
sampler.__index = sampler

local notes = require('notes')
local efx = require('efx')

sampler.logSamples = false

function sampler.new(settings)
  local self = setmetatable({}, sampler)
  self.synths = {} -- collection of sources in an array
  self.masterVolume = 1
  self.looped       = settings.looped or false
  self.transpose = settings.transpose or 0
  self.envelope = settings.envelope or { attack  = 0,     -- default envelope best suited for
                                         decay   = 0,     -- one-shot samples, not for loopes
                                         sustain = 1,
                                         release = 0.35 }
  local synthCount  = settings.synthCount or 6

  self.samples = {}
  -- prepare samples that will be used by synths
  for i,sample in ipairs(settings) do
    local decoder = love.sound.newDecoder(sample.path)
    sample.soundData = love.sound.newSoundData(decoder)
    sample.note = sample.note or 0
    sample.velocity  = sample.velocity or 0.8
    table.insert(self.samples, sample)
  end

  -- initialize synths which will take care of playing samples as per notes
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

function sampler:processTouches(dt, touches)
  -- hunt for new touches and play them
  for id, touch in pairs(touches) do
    if touch.noteRetrigger then
      -- break connection between existing synth and touch
      for i,synth in ipairs(self.synths) do
        if synth.touchId == id then
          synth.touchId = nil
        end
      end
      self:assignSynth(id, touch)
    end
  end
  -- update sources for existing touches
  for i, synth in ipairs(self.synths) do
    if synth.source then
      synth.enveloped = self:applyEnvelope(dt, synth.enveloped, synth.active, synth.duration)
      local volume = synth.enveloped * self.masterVolume
      synth.source:setVolume(volume)

      local touch = touches[synth.touchId]
      if touch and touch.note then           -- update existing note
        local pitch = notes.toPitch(touch.note - synth.note + self.transpose)
        synth.source:setPitch(pitch)
        touch.volume = math.max(volume, touch.volume or 0) -- report max volume for visualization
      else
        synth.active = false                 -- not pressed, let envelope release
      end
    end
    synth.duration = synth.duration + dt
  end
end

function sampler:assignSynth(touchId, touch)
  -- find synth with longest duration
  local maxDuration = -100
  local selected = nil
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
  local sample = self:assignSample(touch.note + self.transpose, touch.pressure)
  synth.path = sample.path
  synth.source = love.audio.newSource(sample.soundData)
  synth.touchId = touchId
  synth.duration = 0
  synth.enveloped = 0
  synth.active = true
  synth.note = sample.note
  efx.applyFilter(synth.source)
  if touch.location then
    synth.source:setPosition(touch.location[1] / 2, touch.location[2] / 2, 0.5)
  end
  synth.source:setLooping(self.looped)
  synth.source:setVolume(0) -- envelope will correct this
  synth.source:play()
  return synth
end

function sampler:assignSample(note, velocity)
  -- first look for closest sample velocity, then for closest pitch
  local bestFitness = math.huge
  local selected = nil
  for i, sample in ipairs(self.samples) do
    local fitness = math.abs(sample.note - note) + 100 * math.abs(sample.velocity - velocity)
    if fitness < bestFitness - .5 then
      selected = i
      bestFitness = fitness
    end
  end
  if sampler.logSamples then
    log(string.format('note = %d, pitch = %1.2f, sample = %s, distance = %d',
      note,
      notes.toPitch(note - self.samples[selected].note),
      self.samples[selected].path,
      note - self.samples[selected].note
      ))
  end
  return self.samples[selected]
end

function sampler:applyEnvelope(dt, vol, active, duration)
  -- ADSR envelope
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
