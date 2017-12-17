local patch = {}

local l = require('lume')
local sampler = require('sampler')
local hexpad = require('hexpad')
local efx = require('efx')

local keyboard
local tone

local colorScheme = {
  skin   = {l.hsl(0.06, 0.38, 0.61)},
  mouth  = {l.hsl(0.00, 1.00, 0.15)},
  hair   = {l.hsl(0.00, 0.00, 0.12)},
  robes  = {l.hsl(0.71, 0.68, 0.55)},
  collar = {l.hsl(0.14, 0.86, 0.64)},
  tongue = {l.hsl(0.00, 0.70, 0.5)},
  fog    = {l.hsl(0.62, 0.21, 0.52)},
  fog    = {l.hsl(0.62, 0.21, 0.52, 0.3)},
}

function patch.load()
  keyboard = hexpad.new(true)
  tone = sampler.new({
    {path='patches/choir/choir_21.ogg',  note= -9},
    {path='patches/choir/choir_15.ogg',  note= -3},
    {path='patches/choir/choir_12.ogg',  note=  0},
    {path='patches/choir/choir_9.ogg',   note=  3},
    {path='patches/choir/choir_6.ogg',   note=  6},
    {path='patches/choir/choir_3.ogg',   note=  9},
    {path='patches/choir/choir_0.ogg',   note= 12},
    {path='patches/choir/choir_-3.ogg',  note= 15},
    {path='patches/choir/choir_-6.ogg',  note= 18},
    looped = true,
    envelope = { attack = 0.30, decay = 0.40, sustain = 0.85, release = 0.35 },
  })
  keyboard.colorScheme.background    = {l.rgba(0x2d2734ff)}
  keyboard.colorScheme.highlight     = {l.rgba(0xe86630ff)}
  keyboard.colorScheme.bright        = {l.rgba(0xa7a2b8ff)}
  keyboard.colorScheme.surface       = {l.hsl(0.62, 0.16, 0.49)}
  keyboard.colorScheme.surfaceC      = {l.hsl(0.62, 0.10, 0.40)}
end

function patch.process(s)
  keyboard:interpret(s)
  efx.reverb.decaytime = l.remap(s.tilt.lp[2], 1, -1, 1, 10)
  tone:update(s.dt, s.touches)
end

function patch.draw(s)
  keyboard:draw(s)
end

function drawDude(time)
  local gape = 0.7 + 0.3 * math.cos(time * 2)^2
  love.graphics.setColor(colorScheme.robes)
  love.graphics.ellipse('fill', 0, 0, 0.5, 0.8)
  love.graphics.setColor(colorScheme.collar)
  love.graphics.ellipse('fill', 0, -0.7, 0.1, 0.6)
  love.graphics.setColor(colorScheme.hair)
  love.graphics.ellipse('fill', 0, -1.1, 0.32, 0.35)
  love.graphics.setColor(colorScheme.skin)
  love.graphics.ellipse('fill', 0, -1.0, 0.3, 0.35)
  love.graphics.setColor(colorScheme.mouth)
  love.graphics.ellipse('fill', 0, -0.85, 0.15, 0.1 * gape)
  love.graphics.setColor(colorScheme.tongue)
  love.graphics.ellipse('fill', 0, -0.85 + 0.05 * gape, 0.07, 0.03 * gape)
end

function patch.icon(time)
  local sway = 0.05
  love.graphics.setColor(colorScheme.fog)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  love.graphics.push()
    love.graphics.translate( 0.5, 0.7)
    love.graphics.rotate(math.cos(time + 4) * sway)
    drawDude(time)
  love.graphics.pop()
  love.graphics.push()
    love.graphics.translate(-0.5, 0.7)
    love.graphics.rotate(math.cos(time + 1) * sway)
    drawDude(time + 0.1)
  love.graphics.pop()
  love.graphics.setColor(colorScheme.fog)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  love.graphics.push()
    love.graphics.translate(0, 1)
    love.graphics.rotate(math.cos(time + 2) * sway)
    love.graphics.scale(1, 1 + 0.04 * math.cos(time * 0.67 + 2))
    drawDude(time - 0.1)
  love.graphics.pop()
end

return patch