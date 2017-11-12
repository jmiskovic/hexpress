shaping = {}

-- collection of sources in a map indexed by touch ID
shaping.sources = {}

function shaping.load(settings)
  local sourceCount = settings.sourceCount or 10
  local path        = settings.samplePath or 'samples/brite48000.wav'
  local looped      = settings.looped or false
  local decoder     = love.sound.newDecoder(path)

  shaping.envelope = settings.envelope or {
    attack  = 0.40,
    decay   = 0.20,
    sustain = 0.85,
    release = 0.35,
  }

  for i=1, sourceCount do
    shaping.sources[i] = love.audio.newSource(decoder)
    shaping.sources[i]:setLooping(looped)
  end
end

function shaping.process(stream)
  -- hunt for new touches and play them
  for id, touch in pairs(stream.touches) do
    if touch.noteRetrigger then
      local source = shaping.sources[id]
      if not source then
        source = shaping.assignSource(stream, id)
      end
      log('restart note %s', touch.noteName)
      touch.envelopeVolume = 0
      source:stop()
      source:play()
    end
  end
  -- update sources for existing touches
  for id, source in pairs(shaping.sources) do
    touch = stream.touches[id]
    if touch then                                   -- update existing notes
      source:setPitch(touch.pitch)
      track('pitch %1.2f', touch.pitch)
    end
    --touch.envelopeVolume = shaping.applyEnvelope(stream, touch)
  end
  return stream
end

function shaping.assignSource(stream, touchId)
  -- find source longest duration
  maxDuration = -1
  selectedId = nil
  for id, source in pairs(shaping.sources) do
    if type(id) == 'number' then        -- not yet assigned
      selectedId = id
      break
    elseif not stream.touches[id] then  -- touch released
      selectedId = id
      break
    elseif stream.touches[id].duration > maxDuration then
      maxDuration = stream.touches[id].duration
      selectedId = id
    end
  end
  -- move source to correct key
  shaping.sources[touchId] = shaping.sources[selectedId]
  shaping.sources[selectedId] = nil
  return shaping.sources[touchId]
end

function shaping.applyEnvelope(stream, touch)
  if not touch then
    return 0 --math.max(touch.envelopeVolume + stream.dt / shaping.envelope.release, 0) -- release
  else
    if shaping.envelope.attack == 0 and touch.duration == 0 then
      return shaping.envelope.sustain
    elseif touch.duration < shaping.envelope.attack then
    return touch.envelopeVolume + stream.dt / shaping.envelope.attack               -- attack
    elseif touch.duration < shaping.envelope.attack + shaping.envelope.decay then
    return touch.envelopeVolume + stream.dt / shaping.envelope.decay                -- decay
    else
    return touch.envelopeVolume                                                     -- sustain
    end
  end
end

return shaping