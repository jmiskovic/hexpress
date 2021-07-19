local patch = {}
patch.__index = patch

local l = require('lume')
local sampler = require('sampler')
local hexpad = require('hexpad')
local efx = require('efx')
local notes = require('notes')

local colorScheme = {
  skin   = {l.hsl(0.06, 0.38, 0.61)},
  mouth  = {l.hsl(0.00, 1.00, 0.15)},
  hair   = {l.hsl(0.00, 0.00, 0.12)},
  suit   = {l.rgba(0x1a212fff)},
  shirt  = {l.rgba(0xf0f0f0ff)},
  glasses= {l.rgba(0x0f0f0fff)},
  tongue = {l.hsl(0.00, 0.70, 0.5)},
  fog    = {l.hsl(0.62, 0.21, 0.52, 0.3)},
}


function patch.load()
  local self = setmetatable({}, patch)
  self.layout = hexpad.new(true, 7)
  self.sampler = sampler.new({
  {path='patches/scat/Daah01.ogg', note=-9, velocity = .1},
  {path='patches/scat/Daah02.ogg', note=-4, velocity = .1},
  {path='patches/scat/Daah03.ogg', note=-1, velocity = .1},
  {path='patches/scat/Daah04.ogg', note= 3, velocity = .1},
  {path='patches/scat/Daah06.ogg', note= 7, velocity = .1},
  {path='patches/scat/Daah07.ogg', note=10, velocity = .1},
  {path='patches/scat/Daah08.ogg', note=13, velocity = .1},
  {path='patches/scat/Daah09.ogg', note=16, velocity = .1},
  {path='patches/scat/Daah10.ogg', note=18, velocity = .1},
  {path='patches/scat/Daah11.ogg', note=21, velocity = .1},
  {path='patches/scat/Daah12.ogg', note=25, velocity = .1},
  {path='patches/scat/Paah01.ogg', note=-9, velocity = .9},
  {path='patches/scat/Paah02.ogg', note=-5, velocity = .9},
  {path='patches/scat/Paah03.ogg', note=0,  velocity = .9},
  {path='patches/scat/Paah04.ogg', note= 4, velocity = .9},
  {path='patches/scat/Paah05.ogg', note= 5, velocity = .9},
  {path='patches/scat/Paah06.ogg', note= 9, velocity = .9},
  {path='patches/scat/Paah07.ogg', note=14, velocity = .9},
  {path='patches/scat/Paah08.ogg', note=17, velocity = .9},
  {path='patches/scat/Paah09.ogg', note=19, velocity = .9},
  {path='patches/scat/Paah10.ogg', note=24, velocity = .9},
  {path='patches/scat/Paah11.ogg', note=28, velocity = .9},
    looped = false,
    transpose = 0,
  })
  self.efx = efx.load()
  self.layout.colorScheme.background    = {l.rgba(0x2d2734ff)}
  self.layout.colorScheme.highlight     = {l.rgba(0xe86630ff)}
  self.layout.colorScheme.text          = {l.rgba(0xa7a2b8ff)}
  self.layout.colorScheme.surface       = {l.hsl(0.62, 0.16, 0.49)}
  self.layout.colorScheme.surfaceC      = {l.hsl(0.62, 0.10, 0.40)}
  return self
end


function patch:process(s)
  for _,touch in pairs(s.touches) do
    touch.velocity = l.remap(s.tilt[1], -0.2, 0.2, 0.1, 0.9, 'clamp')
  end
  self.layout:interpret(s)
  self.efx.reverb.decaytime = l.remap(s.tilt.lp[2], 1, -1, 1, 5)
  self.efx:process()
  self.sampler:processTouches(s.dt, s.touches, self.efx)
end


function patch:draw(s)
  self.layout:draw(s)
end


local function drawDude(time)
  local gape = 0.7 + 0.3 * math.cos(time * 2)^2
  love.graphics.setColor(colorScheme.suit)
  love.graphics.ellipse('fill', 0, 0, 0.5, 0.8)
  love.graphics.setColor(colorScheme.shirt)
  love.graphics.ellipse('fill', 0, -0.7, 0.1, 0.6)
  love.graphics.setColor(colorScheme.hair)
  love.graphics.ellipse('fill', 0, -1.1, 0.32, 0.35)
  love.graphics.setColor(colorScheme.skin)
  love.graphics.ellipse('fill', 0, -1.0, 0.3, 0.35)
  love.graphics.setColor(colorScheme.mouth)
  love.graphics.ellipse('fill', 0, -0.85, 0.15, 0.04 * gape)
  love.graphics.setColor(colorScheme.tongue)
  love.graphics.ellipse('fill', 0, -0.85 + 0.03 * gape, 0.07, 0.02 * gape)
  love.graphics.setColor(colorScheme.glasses)
  love.graphics.ellipse('fill', -0.13, -1.1, 0.15, 0.1, 6)
  love.graphics.ellipse('fill',  0.13, -1.1, 0.15, 0.1, 6)
end


function patch.icon(time)
  local sway = 0.05
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