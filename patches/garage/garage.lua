local patch = {}
patch.__index = patch

local sampler = require('sampler')
local freeform = require('freeform')
local efx = require('efx')
local l = require('lume')

local colorScheme = {
  shade    = {l.rgba(0x00000050)},
  membrane = {l.rgba(0xd7d0aeff)},
  rim      = {l.rgba(0x606060ff)},
  stick    = {l.rgba(0xc0a883ff)},
  background = {l.rgba(0x38404a)},
}


function patch.load()
  local self = setmetatable({}, patch)
  local triggers = { -- elements are listed in draw order (lowest to highest)
    {path='patches/garage/acustic/CyCdh_K3Kick-03.ogg',       type='block',    x= 0.060, y= 0.839, r= 1.22},
    {path='patches/garage/acustic/CYCdh_LudSdStC-04.ogg',     type='block',    x= 0.154, y= 0.094, r= 0.66},
    {path='patches/garage/acustic/CYCdh_K2room_Snr-01.ogg',   type='membrane', x=-0.402, y=-0.076, r= 0.83},
    {path='patches/garage/acustic/CYCdh_K2room_Snr-04.ogg',   type='block',    x=-0.406, y=-0.050, r= 0.60},
    {path='patches/garage/acustic/CyCdh_K3Tom-05.ogg',        type='membrane', x= 0.892, y= 0.109, r= 0.55},
    {path='patches/garage/acustic/CYCdh_Kurz01-Tom03.ogg',    type='membrane', x= 0.204, y=-0.344, r= 0.46},
    {path='patches/garage/acustic/CYCdh_Kurz03-Tom03.ogg',    type='membrane', x=-0.639, y=-0.261, r= 0.38},
    {path='patches/garage/acustic/CYCdh_VinylK1-Tamb.ogg',    type='block',    x= 0.993, y=-0.469, r= 0.46},
    {path='patches/garage/acustic/CYCdh_VinylK4-China.ogg',   type='cymbal',   x=-0.215, y=-0.807, r= 0.43},
    {path='patches/garage/acustic/CYCdh_TrashD-02.ogg',       type='cymbal',   x=-0.904, y=-0.659, r= 0.39},
    {path='patches/garage/acustic/CYCdh_K4-Trash10.ogg',      type='cymbal',   x=-1.357, y=-0.378, r= 0.43},
    {path='patches/garage/acustic/KHats_Open-07.ogg',         type='cymbal',   x= 1.494, y= 0.161, r= 0.40},
    {path='patches/garage/acustic/CYCdh_K2room_ClHat-05.ogg', type='cymbal',   x= 1.279, y=-0.531, r= 0.54},
    {path='patches/garage/acustic/CYCdh_K2room_ClHat-01.ogg', type='block',    x= 1.204, y=-0.701, r= 0.32},
    {path='patches/garage/acustic/CYCdh_VinylK4-Ride01.ogg',  type='cymbal',   x= 0.515, y=-0.742, r= 0.41},
    {path='patches/garage/acustic/CYCdh_Kurz01-Ride01.ogg',   type='block',    x= 0.515, y=-0.737, r= 0.20},
    {path='patches/garage/acustic/CyCdh_K3Crash-02.ogg',      type='cymbal',   x=-1.509, y= 0.211, r= 0.37},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 1.0 },
  }
  self.efx = efx.load()
  self.layout = freeform.new(triggers)
  self.sampler = sampler.new(triggers)
  love.graphics.setBackgroundColor(colorScheme.background)
  return self
end


function patch:process(s)
  self.layout:interpret(s)
  self.efx.reverb.decaytime = l.remap(s.tilt.lp[1], 0.1, -0.5, 0.5, 4)
  self.efx:process()
  self.sampler:processTouches(s.dt, s.touches, self.efx)
  return s
end


function patch:draw(s)
  self.layout:draw(s)
end


function patch.icon(time)
  local speed = 4
  love.graphics.setColor(colorScheme.background)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- drum
  love.graphics.setColor(colorScheme.shade)
  love.graphics.rectangle('fill', -1.22, 0, 2.44, 1)
  love.graphics.ellipse('fill', 0, 1, 1.22, 0.6)
  love.graphics.setColor(colorScheme.membrane)
  love.graphics.ellipse('fill', 0, 0, 1.2, 0.6)
  love.graphics.setLineWidth(0.08)
  love.graphics.setColor(colorScheme.rim)
  love.graphics.ellipse('line', 0, 0, 1.2, 0.6)
  -- left stick
 love.graphics.setColor(colorScheme.stick)
  love.graphics.push()
    love.graphics.translate(-2.2, 0.3)
    love.graphics.rotate(math.pi / 8 - math.pi / 4 * math.abs(math.sin(speed * time)))
    love.graphics.line(-0.5, 0, 1.7, -0.9)
    love.graphics.circle('fill', 1.7, -0.9, 0.07)
  love.graphics.pop()
  -- other-left stick
  love.graphics.push()
    love.graphics.translate(2.2, 0.3)
    love.graphics.rotate(-math.pi / 8 + math.pi / 4 * math.abs(math.cos(speed * time)))
    love.graphics.line(0.5, 0, -1.7, -0.9)
    love.graphics.circle('fill', -1.7, -0.9, 0.07)
  love.graphics.pop()
end


return patch