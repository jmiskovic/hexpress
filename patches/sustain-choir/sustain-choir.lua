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
  highlight  = {l.hsl(0.66, 0.20, 0.23)},
  surface    = {l.rgba(0x444444ff)},
  surfaceC   = {l.rgba(0x353535ff)},
  bright     = {l.rgba(0x75ade699)},
}

function patch.load()
  patch.keyboard = hexpad.new(true)

  patch.tone = sampler.new({
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
    envelope = { attack = 0.05, decay = 0.40, sustain = 0.85, release = 0.35 },
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
  -- slower attack & release when tilted forward
  patch.tone.envelope.attack    = l.remap(s.tilt.lp[2],  .00, -.2, .2, 2, 'clamp')
  patch.tone.envelope.release   = l.remap(s.tilt.lp[2], -.05, -.4, .6, 4, 'clamp')
  efx.reverb.decaytime           = l.remap(s.tilt.lp[2],  .00, -.4, 1,  8, 'clamp')
  -- volume control
  patch.tone.masterVolume   = l.remap(s.tilt.lp[1], -0.1, 0.6, 1, .05, 'clamp')
  patch.tone:processTouches(s.dt, s.touches)
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