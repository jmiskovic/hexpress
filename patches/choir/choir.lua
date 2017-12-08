local patch = {}

local l = require('lume')
local sampler = require('sampler')
local hexpad = require('hexpad')
local efx = require('efx')

local keyboard
local tone

local colorScheme = {
  skin   = {l.rgba(0xfeef01ff)},
  eyes   = {0,0,0},
  mouth  = {l.rgba(0xd5b101ff)},
  tongue = {l.rgba(0xdb6467ff)},
}

function patch.load()
  keyboard = hexpad.new()
  tone = sampler.new({
    {path='patches/choir/choir_15.ogg',  note= -3},
    {path='patches/choir/choir_3.ogg',   note=  9},
    {path='patches/choir/choir_12.ogg',  note=  0},
    {path='patches/choir/choir_0.ogg',   note= 12},
    {path='patches/choir/choir_21.ogg',  note= -9},
    {path='patches/choir/choir_9.ogg',   note=  3},
    {path='patches/choir/choir_-3.ogg',  note= 15},
    {path='patches/choir/choir_6.ogg',   note=  6},
    {path='patches/choir/choir_-6.ogg',  note= 18},
    looped = true,
    envelope = { attack = 0.30, decay = 0.40, sustain = 0.85, release = 0.35 },
  })
end

function patch.process(s)
  keyboard:interpret(s)
  efx.reverb.decaytime = l.remap(s.tilt.lp[2], 1, -1, 1, 10)
  tone:update(s.dt, s.touches)
end

function patch.draw(s)
  keyboard:draw(s)
end

function patch.icon(time)
  love.graphics.setColor(colorScheme.skin)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- looking left and right
  love.graphics.translate(0.12 * math.sin(time), 0)
  -- draw eyes
  local ry = math.abs(0.4 * math.sin(time) * math.sin(3 * time))
  love.graphics.setColor(colorScheme.eyes)
  love.graphics.ellipse('fill', -0.48, -0.36 - ry / 5, 0.1, 0.2)
  love.graphics.ellipse('fill',  0.48, -0.36 - ry / 5, 0.1, 0.2)
  -- draw opening mouth and tongue
  love.graphics.translate(0, 0.3)
  love.graphics.scale(0.6, ry)
  love.graphics.setColor(colorScheme.mouth)
  love.graphics.ellipse('fill', 0, 0, 1, 1, 20)
  love.graphics.setColor(colorScheme.tongue)
  love.graphics.ellipse('fill', 0, 0.4, 0.5, 0.5, 10)
end

return patch