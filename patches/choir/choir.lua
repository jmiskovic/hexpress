local patch = {}

local l = require('lume')
local sampler = require('sampler')
local hexpad = require('hexpad')
local efx = require('efx')

local keyboard
local tone

function patch.load()
  keyboard = hexpad.new()
  tone = sampler.new({
    {path='patches/choir/choir_15.ogg',  note= -3 },
    {path='patches/choir/choir_3.ogg',   note= 9  },
    {path='patches/choir/choir_-21.ogg', note= 33 },
    {path='patches/choir/choir_12.ogg',  note= 0  },
    {path='patches/choir/choir_0.ogg',   note= 12 },
    {path='patches/choir/choir_-24.ogg', note= 36 },
    {path='patches/choir/choir_21.ogg',  note= -9 },
    {path='patches/choir/choir_9.ogg',   note= 3  },
    {path='patches/choir/choir_-3.ogg',  note= 15 },
    {path='patches/choir/choir_-27.ogg', note= 39 },
    {path='patches/choir/choir_6.ogg',   note= 6  },
    {path='patches/choir/choir_-6.ogg',  note= 18 },
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

local colorScheme = {
  white = {l.rgba(0xe5787cff)},
  red   = {l.rgba(0xdb6467ff)},
  pink  = {l.rgba(0xee9f9bff)},
  black = {l.rgba(0x5d3d4dff)},
}

function patch.icon(time)
  love.graphics.scale(1.05 + 0.05 * math.sin(time))
  -- mouth roof
  love.graphics.setColor(colorScheme.red)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  local r = 0.9 + 0.04 * math.cos(time)
  love.graphics.setColor(colorScheme.black)
  love.graphics.ellipse('fill', 0, 0.3, r, r * 0.9)
  -- animated uvula
  local rot = math.pi/16 * math.cos(time * 4)
  love.graphics.push()
  love.graphics.translate(0, -0.4)
  love.graphics.rotate(rot)
  love.graphics.translate(0,  -0.2)
  love.graphics.setColor(colorScheme.red)
  love.graphics.ellipse('fill', 0, 0, 0.2, 0.7)
  love.graphics.setColor(colorScheme.white)
  --love.graphics.translate(0.05, 0.1)
  --love.graphics.ellipse('fill', 0, 0, 0.1, 0.7)
  love.graphics.pop()
  -- tongue
  love.graphics.setColor(colorScheme.pink)
  love.graphics.ellipse('fill', -0.3, 1, 0.6, 0.4)
  love.graphics.ellipse('fill',  0.2, 1, 0.4, 0.3)
end

return patch