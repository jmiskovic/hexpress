efx = {}

local bandpass = {
  volume   = 1.0,
  type     = 'bandpass',
  lowgain  = 1.0,
  highgain = 1.0,
}

local reverb = {
  volume    = 1.0,
  type      = 'reverb',
  decaytime = 1,
}

local tremolo = {
  volume    = 1.0,
  type      = 'ringmodulator',
  frequency = 0.6
}

function efx.load()
  love.audio.setEffect(tremolo.type, tremolo)
  love.audio.setEffect(reverb.type, reverb)
end

function efx.applyFilter(source)
  source:setFilter(bandpass)
  source:setEffect(tremolo.type)
  source:setEffect(reverb.type)
end

function efx.setDryVolume(vol)
  bandpass.volume = vol
  -- TODO: apply to all sources?
end

return efx