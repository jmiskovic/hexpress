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
  tremolo = {
    volume    = 0.0,
    type      = 'ringmodulator',
    frequency = 0.6
  },
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
