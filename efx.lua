local efx = {}
efx.__index = efx

local l = require('lume')

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

function efx.load(trackName)
  local self = setmetatable({}, efx)
  self.trackName = trackName or 'live'
  for name, params in pairs(defaults) do
    self[name] = {}
    for param, value in pairs(params) do
      self[name][param] = value
    end
  end
  self.activeEffects = {}
    -- nice to have a bit of reverb
  self:addEffect(self.reverb)
  return self
end


function efx:effectName(effect)
  return self.trackName .. '_' .. effect.type
end


function efx:addEffect(effect)
  table.insert(self.activeEffects, effect)
end


function efx:process()
  for i,effect in ipairs(self.activeEffects) do
    local ok, err = pcall(love.audio.setEffect, self:effectName(effect), effect)
    --if not ok then log(err) end
  end
end


function efx:applyFilter(source)
  source:setFilter(self.bandpass)
  for i,effect in ipairs(self.activeEffects) do
    source:setEffect(self:effectName(effect))
  end
end

function efx:setDryVolume(vol)
  self.bandpass.volume = vol
end

return efx
