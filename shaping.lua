shaping = {}

-- collection of sources in a map indexed by touch ID
shaping.synths = {}

function shaping.load(settings)
  local sourceCount = settings.sourceCount or 10
  local path        = settings.samplePath or 'samples/brite48000.wav'
  local looped      = settings.looped or true

  shaping.envelope = settings.envelope or {
    attack  = 0.40,
    decay   = 0.20,
    sustain = 0.85,
    release = 0.35,
  }
  shaping.slopes = shaping.getSlopes(shaping.envelope)

  -- shaping.synths is filled as array, but it's a map with touchId as keys
  for i=1, sourceCount do
    local decoder     = love.sound.newDecoder(path)
    shaping.synths[i] = {
      source = love.audio.newSource(decoder),
      volume = 0,
      active = false,
      duration = 0,
    }
    shaping.synths[i].source:setLooping(looped)
    shaping.synths[i].source:stop()
  end
  addDraw(function ()
    drawTable(shaping.synths, 400, 20)
  end)

end

function shaping.process(stream)
  -- hunt for new touches and play them
  for id, touch in pairs(stream.touches) do
    if touch.noteRetrigger then
      local synth = shaping.synths[id]
      if not synth then
        synth = shaping.assignSynth(stream, id)
      end
      synth.duration = 0
      synth.volume = 0
      synth.active = true
      synth.source:stop()
      --synth.source:play()
    end
  end
  -- update sources for existing touches
  for id, synth in pairs(shaping.synths) do
    touch = stream.touches[id]
    if touch then                          -- update existing notes
      synth.source:setPitch(touch.pitch)
    else
      synth.active = false                 -- not pressed, let envelope release
    end
    synth.volume = shaping.applyEnvelope(stream, synth)
    synth.source:setVolume(synth.volume)
    synth.duration = synth.duration + stream.dt
  end
  return stream
end

function shaping.assignSynth(stream, touchId)
  -- find synth with longest duration
  maxDuration = -1
  selectedId = nil
  for id, synth in pairs(shaping.synths) do
    if type(id) == 'number' then        -- not yet assigned
      selectedId = id
      break
    elseif synth.duration > maxDuration then
      maxDuration = synth.duration
      selectedId = id
    end
  end
  -- move source to correct key
  shaping.synths[touchId] = shaping.synths[selectedId]
  shaping.synths[selectedId] = nil
  return shaping.synths[touchId]
end

function shaping.getSlopes(envelope)
  return {
    attack  = 1 / envelope.attack,
    decay   = -(1 - envelope.sustain) / envelope.decay,
    sustain = 0,
    release = - envelope.sustain / envelope.release,
  }
end

function shaping.applyEnvelope(stream, synth)
  if not synth.active then                                                      -- release
    return math.max(0, synth.volume + shaping.slopes.release * stream.dt)
  else
    if shaping.envelope.attack == 0 and synth.duration == 0 then
      return shaping.envelope.sustain
  elseif synth.duration < shaping.envelope.attack then                          -- attack
      return synth.volume + shaping.slopes.attack * stream.dt
  elseif synth.duration < shaping.envelope.attack + shaping.envelope.decay then -- decay
      return synth.volume + shaping.slopes.decay * stream.dt
  else                                                                          -- sustain
      return synth.volume
    end
  end
end

return shaping