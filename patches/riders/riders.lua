local patch = {}
patch.__index = patch

local l = require('lume')
local efx = require('efx')

local sampler = require('sampler')
local hexpad = require('hexpad')

local colorScheme = {
  background = {l.rgba(0x0a0a0cff)},
  highlight  = {l.hsl(0.88, 0.56, 0.46)},
  surface    = {l.hsl(0.66, 0.25, 0.26)},
  surfaceC   = {l.hsl(0.66, 0.20, 0.23)},
  knob       = {l.hsl(0.67, 0.09, 0.15)},
  text       = {l.hsl(0.66, 0.18, 0.38)},
  label      = {l.hsl(0.24, 0.09, 0.72)},
  shiny      = {l.hsl(0.24, 0.09, 0.96, 0.5)},
}


function patch.load()
  local self = setmetatable({}, patch)
  self.layout = hexpad.new(true)

  self.sampler = sampler.new({
    {path='patches/riders/A_029__F1_1.ogg', note =-19, velocity = 0.9},
    {path='patches/riders/A_029__F1_2.ogg', note =-19, velocity = 0.7},
    {path='patches/riders/A_029__F1_3.ogg', note =-19, velocity = 0.5},
    {path='patches/riders/A_029__F1_4.ogg', note =-19, velocity = 0.3},
    {path='patches/riders/A_029__F1_5.ogg', note =-19, velocity = 0.1},
    {path='patches/riders/A_040__E2_1.ogg', note = -8, velocity = 0.9},
    {path='patches/riders/A_040__E2_2.ogg', note = -8, velocity = 0.7},
    {path='patches/riders/A_040__E2_3.ogg', note = -8, velocity = 0.5},
    {path='patches/riders/A_040__E2_4.ogg', note = -8, velocity = 0.3},
    {path='patches/riders/A_040__E2_5.ogg', note = -8, velocity = 0.1},
    {path='patches/riders/A_050__D3_1.ogg', note =  2, velocity = 0.9},
    {path='patches/riders/A_050__D3_2.ogg', note =  2, velocity = 0.7},
    {path='patches/riders/A_050__D3_3.ogg', note =  2, velocity = 0.5},
    {path='patches/riders/A_050__D3_4.ogg', note =  2, velocity = 0.3},
    {path='patches/riders/A_050__D3_5.ogg', note =  2, velocity = 0.1},
    {path='patches/riders/A_062__D4_1.ogg', note = 14, velocity = 0.9},
    {path='patches/riders/A_062__D4_2.ogg', note = 14, velocity = 0.7},
    {path='patches/riders/A_062__D4_3.ogg', note = 14, velocity = 0.5},
    {path='patches/riders/A_062__D4_4.ogg', note = 14, velocity = 0.3},
    {path='patches/riders/A_062__D4_5.ogg', note = 14, velocity = 0.1},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.15 },
    synthCount = 6,
    })
  self.efx = efx.load()
  self.efx:addEffect(self.efx.tremolo)
  self.efx:setDryVolume(0.4)
  self.efx.reverb.volume = 1
  self.efx.reverb.decaytime = 2
  self.efx.tremolo.volume = 1
  self.efx.tremolo.frequency = 4

  self.layout.colorScheme.background = colorScheme.background
  self.layout.colorScheme.highlight  = colorScheme.highlight
  self.layout.colorScheme.surface    = colorScheme.surface
  self.layout.colorScheme.surfaceC   = colorScheme.surfaceC
  self.layout.colorScheme.text       = colorScheme.text
  love.graphics.setBackgroundColor(colorScheme.background)
  return self
end


function patch:process(s)
  self.layout:interpret(s)
  for _,touch in pairs(s.touches) do
    touch.velocity = l.remap(s.tilt[2], 0.2, 0.7, 0.1, 1, 'clamp')
  end
  self.sampler.masterVolume = l.remap(s.tilt[2], 0.2, 0.7, 0.3, 1, 'clamp')
  self.efx.tremolo.frequency = l.remap(s.tilt.lp[1], 0,  0.5, 0, 10, 'clamp')
  self.efx:process()

  self.sampler:processTouches(s.dt, s.touches, self.efx)
end


function patch:draw(s)
  self.layout:draw(s)
end


function patch.icon(time)
  local font = hexpad.font
  -- background
  love.graphics.setColor(colorScheme.surface)
  love.graphics.rectangle('fill', -2, -2, 4, 4)
  -- knob notch marker
  love.graphics.translate(0, 0.4)
  love.graphics.setColor(colorScheme.label)
  love.graphics.arc('fill', 0, -0.78, 0.18, -math.pi / 2 - math.pi / 5, -math.pi / 2 + math.pi / 5)
  -- knob
  love.graphics.setColor(colorScheme.knob)
  love.graphics.circle('fill', 0, 0, 0.8)
  love.graphics.setColor(colorScheme.surfaceC)
  love.graphics.circle('line', 0, 0, 0.43)
  love.graphics.setColor(colorScheme.highlight)
  love.graphics.circle('fill', 0, 0, 0.4)
  -- knob highlight
  love.graphics.setColor(colorScheme.shiny)
  love.graphics.arc('fill', 0, 0, 0.4, 0, math.pi / 6)
  love.graphics.arc('fill', 0, 0, 0.4, math.pi,  math.pi + math.pi / 6)
  -- number markings
  love.graphics.setFont(font)
  love.graphics.setColor(colorScheme.text)
  love.graphics.rotate(math.sin(time / 4) - math.pi / 2)
  for i=1,10 do
    love.graphics.push()
      love.graphics.translate(0, -0.8)
      love.graphics.scale(0.004)
      love.graphics.print(i, -font:getWidth(i) / 2, 0)
    love.graphics.pop()
    love.graphics.rotate(math.pi * 3 / 2 / 10)
  end
end


return patch
