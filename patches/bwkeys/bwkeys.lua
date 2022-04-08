local patch = {}
patch.__index = patch

local l = require('lume')
local efx = require('efx')

local notes = require'notes'
local sampler = require('sampler')
local freeform = require('freeform')

local colorScheme = {
  background    = {l.rgba(0x4c2c38ff)},
  highlight     = {l.rgba(0xff823bff)},
  surface       = {l.rgba(0xf6d3b3ff)},
  black         = {l.rgba(0x100A0Aff)},
  outline       = {l.rgba(0x604b46ff)},
}

local octave_triggers = {
  {type='whitekey', note=  -7, x=-2.300 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=  -5, x=-1.970 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=  -3, x=-1.640 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=  -1, x=-1.310 + 0.1, y= 0.00, r= 0.16},
  {type='blackkey', note=  -6, x=-2.135 + 0.1, y=-0.22, r= 0.12},
  {type='blackkey', note=  -4, x=-1.805 + 0.1, y=-0.22, r= 0.12},
  {type='blackkey', note=  -2, x=-1.475 + 0.1, y=-0.22, r= 0.12},
  {type='whitekey', note=   0, x=-0.980 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=   2, x=-0.650 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=   4, x=-0.320 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=   5, x= 0.010 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=   7, x= 0.340 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=   9, x= 0.670 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=  11, x= 1.000 + 0.1, y= 0.00, r= 0.16},
  {type='blackkey', note=   1, x=-0.815 + 0.1, y=-0.22, r= 0.12},
  {type='blackkey', note=   3, x=-0.485 + 0.1, y=-0.22, r= 0.12},
  {type='blackkey', note=   6, x= 0.175 + 0.1, y=-0.22, r= 0.12},
  {type='blackkey', note=   8, x= 0.505 + 0.1, y=-0.22, r= 0.12},
  {type='blackkey', note=  10, x= 0.835 + 0.1, y=-0.22, r= 0.12},
  {type='whitekey', note=  12, x= 1.330 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=  14, x= 1.660 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=  16, x= 1.990 + 0.1, y= 0.00, r= 0.16},
  {type='whitekey', note=  17, x= 2.320 + 0.1, y= 0.00, r= 0.16},
  {type='blackkey', note=  13, x= 1.495 + 0.1, y=-0.22, r= 0.12},
  {type='blackkey', note=  15, x= 1.825 + 0.1, y=-0.22, r= 0.12},
  {type='blackkey', note=  18, x= 2.155 + 0.1, y=-0.22, r= 0.12},
}


function patch.load()
  local self = setmetatable({}, patch)
  self.triggers = {}
  for octave = 1, -1, -1 do
    for i, trigger in ipairs(octave_triggers) do
      local t = { type=trigger.type, r=trigger.r }
      t.note = trigger.note - octave * 12
      t.x = trigger.x + (octave % 2 == 0 and 0.3 or 0)
      t.y = trigger.y + octave * 0.65
      t.x = t.x + love.math.randomNormal(0.001, 0)
      t.y = t.y + love.math.randomNormal(0.002, 0)
      table.insert(self.triggers, t)
    end
  end
  patch.layout = freeform.new(self.triggers)
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
  self.efx:addEffect(self.efx.flanger)
  self.efx:setDryVolume(0.4)
  self.efx.reverb.volume = 1
  self.efx.reverb.decaytime = 2
  self.efx.tremolo.volume = 1
  self.efx.tremolo.frequency = 4
  patch.layout.colorScheme.whitekey = colorScheme.surface
  patch.layout.colorScheme.blackkey = colorScheme.black
  love.graphics.setBackgroundColor(colorScheme.background)
  return self
end


function patch:process(s)
  patch.layout:interpret(s)
  for _,touch in pairs(s.touches) do
    touch.velocity = l.remap(s.tilt[2], 0.2, 0.7, 0.1, 1, 'clamp')
  end
  self.sampler.masterVolume =  l.remap(s.tilt[2], 0.2, 0.7, 0.2, 1, 'clamp')
  self.efx.tremolo.frequency = l.remap(s.tilt.lp[1], 0, 0.3, 0, 5)
  self.efx.flanger.volume    = l.remap(s.tilt.lp[1], 0, -0.2, 0.2, 1, 'clamp')
  self.efx.flanger.rate      = l.remap(s.tilt.lp[1], 0, -0.7, 0, 1, 'clamp')
  self.efx:process()
  self.sampler:processTouches(s.dt, s.touches, self.efx)
end


function patch:draw(s)
  patch.layout:draw(s)
end


patch.icon_drawer = freeform.new(octave_triggers)

function patch.icon(time)
  love.graphics.scale(4)
  love.graphics.translate(-0.5 + (time * 0.2) % 2.3, 0)
  patch.icon_drawer:draw({})
end


return patch
