sampler = {}
sampler.__index = sampler

local efx = require('efx')


function sampler.new(settings)
  local self = setmetatable({}, sampler)

  self.synths = {} -- collection of sources in a map
  self.transpose    = settings.transpose or 0
  local sourceCount = settings.sourceCount or 6
  local path        = settings.path
  local looped      = settings.looped or false

  self.envelope = settings.envelope or {
    attack  = 0,
    decay   = 0,
    sustain = 1,
    release = 0.35,
  }
  self.slopes = self:getSlopes(self.envelope)
  self.masterVolume = 1

  for i=1, sourceCount do
    local decoder = love.sound.newDecoder(path)
    self.synths[i] = {
      source = love.audio.newSource(decoder),
      volume = 0,
      active = false,
      duration = math.huge,
      enveloped = 0,
    }
    self.synths[i].source:setLooping(looped)
    self.synths[i].source:stop()
    efx.applyFilter(self.synths[i].source)
  end
  return self
end

function sampler:update(dt, touches)
  -- hunt for new touches and play them
  for id, touch in pairs(touches) do
    if touch.noteRetrigger then
      local synth = self:assignSynth(id)
      synth.touchId = id
      synth.duration = 0
      synth.enveloped = 0
      synth.volume   = 0
      synth.active = true
      synth.source:stop()
      synth.source:play()
      synth.source:setPosition(touch.qr[1]/4, touch.qr[2]/4, 0.5)
    end
  end
  -- update sources for existing touches
  for i, synth in ipairs(self.synths) do
    local touch = touches[synth.touchId]
    if touch and touch.note then           -- update existing notes
      local pitch = self:noteToPitch(touch.note)
      synth.source:setPitch(pitch)
    else
      synth.active = false                 -- not pressed, let envelope release
    end
    synth.enveloped = self:applyEnvelope(dt, synth.enveloped, synth.active, synth.duration)
    synth.volume = synth.enveloped * self.masterVolume
    synth.source:setVolume(synth.volume)
    if touches[synth.touchId] then
      touches[synth.touchId].volume = synth.volume
    end
    synth.duration = synth.duration + dt
  end
end

function sampler:noteToPitch(note)
  -- equal temperament
  return math.pow(math.pow(2, 1/12), note + self.transpose)
end

function sampler:assignSynth(touchId)
  -- find synth with longest duration
  maxDuration = -1
  selected = nil
  for i, synth in ipairs(self.synths) do
    if synth.duration > maxDuration then
      maxDuration = synth.duration
      selected = i
    end
  end
  -- move source to correct key
  local synth = self.synths[selected]
  synth.touchId = touchId
  return synth
end

function sampler:getSlopes(envelope)
  return {
    attack  = 1 / envelope.attack,
    decay   = -(1 - envelope.sustain) / envelope.decay,
    sustain = 0,
    release = - envelope.sustain / envelope.release,
  }
end

function sampler:applyEnvelope(dt, enveloped, active, duration)
  if active then
    if self.envelope.attack == 0 and duration < 0.01 then                                 -- flat
      return self.envelope.sustain
    elseif duration < self.envelope.attack then                       -- attack
      return enveloped + self.slopes.attack * dt
    elseif duration < self.envelope.attack + self.envelope.decay then -- decay
      return enveloped + self.slopes.decay * dt
    else                                                              -- sustain
      return enveloped
    end
  else                                                                -- release
    return math.max(0, enveloped + self.slopes.release * dt)
  end
end

return sampler