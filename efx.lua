local efx = {}

local defaults = {
  bandpass = {
    volume   = 1.0,
    type     = 'bandpass',
    lowgain  = 1.0,
    highgain = 1.0,
  },
  reverb = {
    volume    = 1.0,
    type      = 'reverb',
    decaytime = 1,
  },
  distortion = {
    gain        = 0.05,
    edge        = 0.2,
    lowcut      = 8000.0,
    center      = 24000.0,
    bandwidth   = 36000.0,
    type        = 'distortion',
  },
  echo = {
    volume    = 1.0,
    delay     = 0.0,
    tapdelay  = 0.0,
    damping   = 0.0,
    feedback  = 0.0,
    spread    = 0.0,
    type      = 'echo',
  },
  tremolo = {
    volume    = 0.8,
    frequency = 440.0,
    waveform  = 'sine',
    highcut   = 800.0,
    type      = 'ringmodulator',
  },
  flanger = {
    waveform  = 'triangle',
    volume    = 1.0,
    phase     = 0,
    rate      = 0.27,
    depth     = 1,
    feedback  = -0.5,
    delay     = 0.002,
    type      = 'flanger',
  }
}

efx.activeEffects = {}

function resetEffects()
  for name, params in pairs(defaults) do
    efx[name] = {}
    for param, value in pairs(params) do
      efx[name][param] = value
    end
  end
  efx.activeEffects = {efx.reverb}  -- nice to have a bit of reverb
end

resetEffects()


function efx.load()
  resetEffects()
  for i,effect in ipairs(efx.activeEffects) do
    local ok, err = pcall(love.audio.setEffect, effect.type, effect)
  end
end

function efx.addEffect(effect)
  -- some platforms don't have all effects, ignore request if not available
  local ok, result = pcall(love.audio.setEffect, effect.type, effect)
  if ok then
    table.insert(efx.activeEffects, effect)
  else
    -- log(err)
  end
  return ok
end

function efx.process(s)
  for i,effect in ipairs(efx.activeEffects) do
    local ok, err = pcall(love.audio.setEffect, effect.type, effect)
    --if not ok then log(err) end
  end
end

function efx.applyFilter(source)
  source:setFilter(efx.bandpass)
  for i,effect in ipairs(efx.activeEffects) do
    source:setEffect(effect.type)
  end
end

function efx.setDryVolume(vol)
  efx.bandpass.volume = vol
end

return efx
