local efx = {}

efx.bandpass = {
  volume   = 1.0,
  type     = 'bandpass',
  lowgain  = 1.0,
  highgain = 1.0,
}

efx.reverb = {
  volume    = 1.0,
  type      = 'reverb',
  decaytime = 1,
}

efx.tremolo = {
  volume    = 1.0,
  type      = 'ringmodulator',
  frequency = 0.6
}

efx.activeEffects = {
  efx.reverb,               -- nice to have a bit of reverb
}

function efx.load()
  for i,effect in ipairs(efx.activeEffects) do
    love.audio.setEffect(effect.type, effect)
  end
end

function efx.addEffect(effect)
  table.insert(efx.activeEffects, effect)
  love.audio.setEffect(effect.type, effect)
end

function efx.process(s)
  for i,effect in ipairs(efx.activeEffects) do
    ok, err = pcall(love.audio.setEffect, effect.type, effect)
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