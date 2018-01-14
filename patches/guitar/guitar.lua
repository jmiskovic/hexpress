local patch = {}
local l = require("lume")
local efx = require('efx')
local sampler = require('sampler')
local fretboard = require('fretboard')

local colorScheme = {
  wood    = {l.hsl(0.09, 0.05, 0.16)},
  neck    = {l.rgba(0x2f2c26ff)},
  fret    = {l.hsl(0, 0, 0.5)},
  string  = {l.hsl(0, 0, 0.5)},
  dot     = {l.rgba(0xffffffc0)},
  light   = {l.rgba(0xffffffc0)},
  nut     = {l.rgba(0xffffffc0)},
}

function patch.load()
  efx.reverb.decaytime = 2
  patch.keyboard = fretboard.new(false, 'EBGDAE')
  patch.keyboard.colorScheme = colorScheme
  patch.clean = sampler.new({
    {path='patches/guitar/normGBLow_40.ogg', note =  40 - 60},
    {path='patches/guitar/normGBLow_46.ogg', note =  46 - 60},
    {path='patches/guitar/normGBLow_52.ogg', note =  52 - 60},
    {path='patches/guitar/normGBLow_58.ogg', note =  58 - 60},
    {path='patches/guitar/normGBLow_64.ogg', note =  64 - 60},
    {path='patches/guitar/normGBLow_70.ogg', note =  70 - 60},
    {path='patches/guitar/normGBLow_76.ogg', note =  76 - 60},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 1.8 },
    })

  patch.dirty = sampler.new({
    {path='patches/guitar/pic1_F#1.ogg', note = -30 + 12 },
    {path='patches/guitar/pic2_B2.ogg',  note = -25 + 12 },
    {path='patches/guitar/pic4_C3.ogg',  note = -12 + 12 },
    {path='patches/guitar/pic6_C4.ogg',  note =   0 + 12 },
    {path='patches/guitar/pic3_F#2.ogg', note =   6 + 12 },
    {path='patches/guitar/pic8_C5.ogg',  note =  12 + 12 },
    {path='patches/guitar/pic5_F#3.ogg', note =  18 + 12 },
    {path='patches/guitar/pic7_F#4.ogg', note =  30 + 12 },
    envelope = { attack = 0, decay = 0, sustain = 1, release = 1.8 },
    })

  patch.power = sampler.new({
    {path='patches/guitar/cho1_F#1.ogg', note = -30 + 12},
    {path='patches/guitar/cho2_C2.ogg',  note = -24 + 12},
    {path='patches/guitar/cho3_F#2.ogg', note = -18 + 12},
    {path='patches/guitar/cho4_C3.ogg',  note = -12 + 12},
    {path='patches/guitar/cho5_F#3.ogg', note =  -6 + 12},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.2 },
    })

  patch.sustn = sampler.new({
    {path='patches/guitar/sus1_F#1.ogg', note = -30 + 12},
    {path='patches/guitar/sus2_C2.ogg',  note = -24 + 12},
    {path='patches/guitar/sus3_F#2.ogg', note = -18 + 12},
    {path='patches/guitar/sus4_C3.ogg',  note = -12 + 12},
    {path='patches/guitar/sus5_F#3.ogg', note =  -6 + 12},
    envelope = { attack = 5, decay = 0, sustain = 1, release = 0.2 },
    looped = true,
    })

  love.graphics.setBackgroundColor(colorScheme.wood)
end

function patch.process(s)
  patch.keyboard:interpret(s)
  -- whammy bar
  for _,touch in pairs(s.touches) do
    if touch.note then
      touch.note = l.remap(s.tilt.lp[2], -0.2, -1, touch.note, touch.note - 3, 'clamp')
    end
  end
  -- increase the duration of released notes with vertical tilt
  patch.clean.envelope.release = l.remap(s.tilt.lp[2], 0.7, -0.5, 0.2, 5,   'clamp')
  patch.dirty.envelope.release = l.remap(s.tilt.lp[2], 0.7, -0.5, 0.2, 2,   'clamp')
  patch.power.envelope.release = l.remap(s.tilt.lp[2], 0.7, -0.5, 0.2, 1,   'clamp')
  -- crossfade between clean / dirty / dirty+power
  patch.clean.masterVolume = l.remap(s.tilt.lp[1],-0.2, 0.1, 1, 0, 'clamp')
  patch.dirty.masterVolume = l.remap(s.tilt.lp[1],-0.1, 0.2, 0, 1, 'clamp')
  patch.power.masterVolume = l.remap(s.tilt.lp[1], 0.2, 0.3, 0, 1, 'clamp')
  patch.sustn.masterVolume = l.remap(s.tilt.lp[1], 0.2, 0.3, 0, 1, 'clamp')

  patch.clean:processTouches(s.dt, s.touches)
  patch.dirty:processTouches(s.dt, s.touches)
  patch.power:processTouches(s.dt, s.touches)
  patch.sustn:processTouches(s.dt, s.touches)
  return s
end

function patch.draw(s)
  patch.keyboard:draw(s)
  -- draw nut
  local fretX = -0.4 * 4
  love.graphics.setLineWidth(0.09)
  love.graphics.setColor(colorScheme.nut)
  love.graphics.line(fretX, -patch.keyboard.neckWidth / 2 * 1.05, fretX, patch.keyboard.neckWidth / 2 * 1.05)
  -- dots
  love.graphics.setColor(colorScheme.dot)
  love.graphics.circle('fill', 0.2, 0, 0.05)
  love.graphics.circle('fill', 1.0, 0, 0.05)

end

function patch.icon(time, s)
  -- neck
  love.graphics.setColor(colorScheme.neck)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- dot
  love.graphics.setColor(colorScheme.dot)
  love.graphics.circle('fill', 0, 0, 0.4)
  -- strings
  love.graphics.setLineWidth(0.08)
  love.graphics.setColor(colorScheme.string)
  love.graphics.line(-1, -0.7, 1, -0.7 + math.sin(50*time) * 0.02)
  love.graphics.line(-1, 0.7 , 1,  0.7)
  love.graphics.setLineWidth(0.04)
  love.graphics.setColor(colorScheme.light)
  love.graphics.line(-1, -0.7, 1, -0.7 + math.sin(50*time) * 0.02)
  love.graphics.line(-1, 0.7 , 1,  0.7)
end

return patch