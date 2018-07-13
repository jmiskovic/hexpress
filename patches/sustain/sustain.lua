local patch = {}
local l = require("lume")
local efx = require('efx')
local sampler = require('sampler')
local hexpad = require('hexpad')
local hexgrid = require('hexgrid')

local colorScheme = {
  wood    = {l.color('#8c3c00')},
  neck    = {l.color('#302400')},
  strings = {
    {l.color('#a69b87')},
    {l.color('#988c75')},
    {l.color('#847965')},
  },
  hair    = {l.color('#a39782')},
  stick   = {l.color('#5e2400')},



  background = {l.rgba(0x262626ff)},
  highlight  = {l.rgba(0x44617bff)},
  surface    = {l.rgba(0x444444ff)},
  surfaceC   = {l.rgba(0x404040ff)},
  bright     = {l.rgba(0x75ade699)},
}

function patch.load()
  patch.keyboard = hexpad.new(true)

  patch.cello = sampler.new({
    {path='patches/strings/susvib_A2_v3.ogg', note=  9},
    {path='patches/strings/susvib_B1_v3.ogg', note= -1},
    {path='patches/strings/susvib_C1_v3.ogg', note=-12},
    {path='patches/strings/susvib_C3_v3.ogg', note= 12},
    {path='patches/strings/susvib_D2_v3.ogg', note=  2},
    {path='patches/strings/susvib_D4_v3.ogg', note= 26},
    {path='patches/strings/susvib_E1_v3.ogg', note= -8},
    {path='patches/strings/susvib_E3_v3.ogg', note= 16},
    {path='patches/strings/susvib_F2_v3.ogg', note=  5},
    {path='patches/strings/susvib_F4_v3.ogg', note= 29},
    {path='patches/strings/susvib_G1_v3.ogg', note= -5},
    {path='patches/strings/susvib_G3_v3.ogg', note= 19},
    looped = true,
    envelope = {attack = 0.2, decay = 0.1, sustain = 0.8, release = 0.6},
    synthCount = 12,
  })
  patch.keyboard.colorScheme.background = colorScheme.background
  patch.keyboard.colorScheme.highlight  = colorScheme.highlight
  patch.keyboard.colorScheme.surface    = colorScheme.surface
  patch.keyboard.colorScheme.surfaceC   = colorScheme.surfaceC
  patch.keyboard.colorScheme.bright     = colorScheme.bright
  love.graphics.setBackgroundColor(colorScheme.background)
end

local pressing = false
local sustained = {}
local previous = {}
local sustainedCount = 0
function sustain(s)
  if next(s.touches) then
    -- erase previous sustains on next touch
    if not pressing then
      previous = sustained
      sustained = {}
      sustainedCount = 0
    end
    pressing = true
    -- remember touched notes
    for _,touch in pairs(s.touches) do
      if touch.note and not sustained[touch.note] then
        sustained[touch.note] = touch
        sustainedCount = sustainedCount + 1
      end
    end
  else
    -- if sustained note is re-pressed, stop playing
    if pressing and sustainedCount == 1 then
      local note, touch = next(sustained)
      if previous[note] then
        sustained = {}
        previous = {}
        sustainedCount = 0
      end
    end
    -- simulate sustained notes
    local i = 1000
    for note, data in pairs(sustained) do
      s.touches[i] = data
      s.touches[i].noteRetrigger = pressing -- this will be true on first pass after touch release
      i = i + 1
    end
    pressing = false
  end
end

function patch.process(s)
  patch.keyboard:interpret(s)
  sustain(s)
  -- slow attack with forward tilt
  patch.cello.envelope.attack    = l.remap(s.tilt.lp[2], 0.0, -0.9, 0.2, 10, 'clamp')
  patch.cello.envelope.release   = l.remap(s.tilt.lp[2], -0.05, -0.2, 0.6, 4, 'clamp')
  efx.reverb.decaytime     = l.remap(s.tilt.lp[2], 0.0, -0.9, 1.0, 8.0, 'clamp')
  -- crossfade between instruments
  patch.cello.masterVolume   = l.remap(s.tilt.lp[1], -0.2, 0.3, 1, 0.2, 'clamp')
  patch.cello:processTouches(s.dt, s.touches)
  return s
end

function patch.draw(s)
  patch.keyboard:draw(s)
end

function patch.icon(time)
  -- TODO: meaningful icon
  love.graphics.setColor(colorScheme.background)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  local i = 0
  love.graphics.rotate(time/5 + 0.2*math.sin(time))
  for q, r in hexgrid.spiralIter(0, 0, 1) do
    if i % 2 == 0 then
      love.graphics.setColor(colorScheme.highlight)
    else
      love.graphics.setColor(colorScheme.surface)
    end
    love.graphics.push()
    local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.scale(0.25)
      local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.translate(x,y)
      love.graphics.circle('fill', x, y, 1.6)
    love.graphics.pop()
    i = i + 1
  end
end

return patch