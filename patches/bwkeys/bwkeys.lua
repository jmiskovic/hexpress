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
  {type='whitekey', note=   0, x=0.000, y= 0.00, r= 0.16},
  {type='whitekey', note=   2, x=0.330, y= 0.00, r= 0.16},
  {type='whitekey', note=   4, x=0.660, y= 0.00, r= 0.16},
  {type='whitekey', note=   5, x=0.990, y= 0.00, r= 0.16},
  {type='whitekey', note=   7, x=1.320, y= 0.00, r= 0.16},
  {type='whitekey', note=   9, x=1.650, y= 0.00, r= 0.16},
  {type='whitekey', note=  11, x=1.980, y= 0.00, r= 0.16},
  {type='blackkey', note=   1, x=0.165, y=-0.22, r= 0.12},
  {type='blackkey', note=   3, x=0.495, y=-0.22, r= 0.12},
  {type='blackkey', note=   6, x=1.155, y=-0.22, r= 0.12},
  {type='blackkey', note=   8, x=1.485, y=-0.22, r= 0.12},
  {type='blackkey', note=  10, x=1.815, y=-0.22, r= 0.12},
}

function patch.load()
  local self = setmetatable({}, patch)
  self.triggers = {}
  local octave = -2
  for y = 0.65, -0.65, -0.65 do
    local x = -3 + y * 1.1
    while x < 3 do
      for _, trigger in ipairs(octave_triggers) do
        if x + trigger.x > -2.5 and x + trigger.x < 2.5 then
          local key = { type=trigger.type, r=trigger.r }
          key.note = trigger.note + octave * 12
          key.x = x + trigger.x
          key.y = y + trigger.y
          key.x = key.x + love.math.randomNormal(0.001, 0)
          key.y = key.y + love.math.randomNormal(0.002, 0)
          table.insert(self.triggers, key)
        end
      end
      x = x + 0.33 * 7
      octave = octave + 1
    end
    octave = octave - 2
  end
  patch.layout = freeform.new(self.triggers)
  self.sampler = sampler.new({
    {path='patches/bwkeys/Ab4-97-127.ogg', note=notes.toIndex['G#4'], velocity=0.8},
    {path='patches/bwkeys/Ab4-1-48.ogg', note=notes.toIndex['G#4'], velocity=0.2},
    {path='patches/bwkeys/Ab3-97-127.ogg', note=notes.toIndex['G#3'], velocity=0.8},
    {path='patches/bwkeys/Ab3-1-48.ogg', note=notes.toIndex['G#3'], velocity=0.2},
    {path='patches/bwkeys/Ab2-97-127.ogg', note=notes.toIndex['G#2'], velocity=0.8},
    {path='patches/bwkeys/Ab2-1-48.ogg', note=notes.toIndex['G#2'], velocity=0.2},
    {path='patches/bwkeys/Ab1-97-127.ogg', note=notes.toIndex['G#1'], velocity=0.8},
    {path='patches/bwkeys/Ab1-1-48.ogg', note=notes.toIndex['G#1'], velocity=0.2},
    {path='patches/bwkeys/E4-97-127.ogg',  note=notes.toIndex['E4'], velocity=0.8},
    {path='patches/bwkeys/E4-1-48.ogg',  note=notes.toIndex['E4'], velocity=0.2},
    {path='patches/bwkeys/E3-97-127.ogg',  note=notes.toIndex['E3'], velocity=0.8},
    {path='patches/bwkeys/E3-1-48.ogg',  note=notes.toIndex['E3'], velocity=0.2},
    {path='patches/bwkeys/E2-97-127.ogg',  note=notes.toIndex['E2'], velocity=0.8},
    {path='patches/bwkeys/E2-1-48.ogg',  note=notes.toIndex['E2'], velocity=0.2},
    {path='patches/bwkeys/C5-97-127.ogg',  note=notes.toIndex['C5'], velocity=0.8},
    {path='patches/bwkeys/C5-1-48.ogg',  note=notes.toIndex['C5'], velocity=0.2},
    {path='patches/bwkeys/C4-97-127.ogg',  note=notes.toIndex['C4'], velocity=0.8},
    {path='patches/bwkeys/C4-1-48.ogg',  note=notes.toIndex['C4'], velocity=0.2},
    {path='patches/bwkeys/C3-97-127.ogg',  note=notes.toIndex['C3'], velocity=0.8},
    {path='patches/bwkeys/C3-1-48.ogg',  note=notes.toIndex['C3'], velocity=0.2},
    {path='patches/bwkeys/C2-97-127.ogg',  note=notes.toIndex['C2'], velocity=0.8},
    {path='patches/bwkeys/C2-1-48.ogg',  note=notes.toIndex['C2'], velocity=0.2},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.15 },
    synthCount = 8,
    })
  self.efx = efx.load()
  self.efx:addEffect(self.efx.tremolo)
  self.efx:setDryVolume(0.4)
  self.efx.reverb.volume = 1
  self.efx.reverb.decaytime = 2.5
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
  self.sampler.masterVolume =  l.remap(s.tilt[2], 0.2, 0.7, 0.4, 1, 'clamp')
  self.efx.tremolo.frequency = l.remap(s.tilt.lp[1], 0.05, 0.3, 0, 3)
  self.efx:process()
  self.sampler:processTouches(s.dt, s.touches, self.efx)
end


function patch:draw(s)
  patch.layout:draw(s)
end


patch.icon_drawer = freeform.new(octave_triggers)


function patch.icon(time)
  love.graphics.scale(4)
  love.graphics.translate(-4 + (time * 0.1) % (0.33*7), 0)
  patch.icon_drawer:draw({})
  love.graphics.translate(0.33*7, 0)
  patch.icon_drawer:draw({})
end


return patch
