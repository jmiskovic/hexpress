local patch = {}
local l = require("lume")
local efx = require('efx')
local sampler = require('sampler')
local fretboard = require('fretboard')

local keyboard
local cello, doublebass
local colorScheme = {
  neck    = {l.rgba(0x2f2c26ff)},
  fret    = {l.hsl(0, 0, 0.5)},
  string  = {l.hsl(0, 0, 0.5)},
  dot     = {l.rgba(0x84816bff)},
  highlight = {l.rgba(0xffffffc0)},
}

function patch.load()
  --local hexpad = require('hexpad')
  -- keyboard = hexpad.new()
  efx.reverb.decaytime = 2
  keyboard = fretboard.new()
  clean = sampler.new({
    {path='patches/guitar/normGBLow_40.ogg', note =  40 - 60},
    {path='patches/guitar/normGBLow_46.ogg', note =  46 - 60},
    {path='patches/guitar/normGBLow_52.ogg', note =  52 - 60},
    {path='patches/guitar/normGBLow_58.ogg', note =  58 - 60},
    {path='patches/guitar/normGBLow_64.ogg', note =  64 - 60},
    {path='patches/guitar/normGBLow_70.ogg', note =  70 - 60},
    {path='patches/guitar/normGBLow_76.ogg', note =  76 - 60},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 1.8 },
    })

  dirty = sampler.new({
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

  power = sampler.new({
    {path='patches/guitar/cho1_F#1.ogg', note = -30 + 12},
    {path='patches/guitar/cho2_C2.ogg',  note = -24 + 12},
    {path='patches/guitar/cho3_F#2.ogg', note = -18 + 12},
    {path='patches/guitar/cho4_C3.ogg',  note = -12 + 12},
    {path='patches/guitar/cho5_F#3.ogg', note =  -6 + 12},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.2 },
    })

  love.graphics.setBackgroundColor(colorScheme.neck)
end

function patch.process(s)
  keyboard:interpret(s)
  clean.envelope.release = l.remap(s.tilt.lp[2], 0.7, -0.5, 0.2, 5,   'clamp')
  dirty.envelope.release = l.remap(s.tilt.lp[2], 0.7, -0.5, 0.2, 2,   'clamp')
  power.envelope.release = l.remap(s.tilt.lp[2], 0.7, -0.5, 0.2, 1,   'clamp')

  clean.masterVolume = l.remap(s.tilt.lp[1],-0.2, 0.1, 1, 0, 'clamp')
  dirty.masterVolume = l.remap(s.tilt.lp[1],-0.1, 0.2, 0, 1, 'clamp')
  power.masterVolume = l.remap(s.tilt.lp[1], 0.2, 0.3, 0, 1, 'clamp')

  clean:update(s.dt, s.touches)
  dirty:update(s.dt, s.touches)
  power:update(s.dt, s.touches)
  return s
end

function patch.draw(s)
  keyboard:draw(s)
end

function patch.icon(time)
  -- neck
  love.graphics.setColor(colorScheme.neck)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- strings
  love.graphics.setLineWidth(0.08)
  love.graphics.setColor(colorScheme.string)
  love.graphics.line(-1, 0.7 , 1, 0.7 + math.sin(50*time) * 0.02)
  love.graphics.line(-1, -0.7, 1, -0.7)
  love.graphics.setLineWidth(0.01)
  love.graphics.setColor(colorScheme.highlight)
  love.graphics.line(-1, 0.7 , 1, 0.7 + math.sin(50*time) * 0.02)
  love.graphics.line(-1, -0.7, 1, -0.7)
  love.graphics.circle('fill', 0, 0, 0.4)
end

return patch


--[[

{path='patches/guitar/dist-e.ogg', note =  -20},
    {path='patches/guitar/dist-a.ogg', note =  -15},
    {path='patches/guitar/dist-d.ogg', note =  -10},


    {path='patches/guitar/a2_f_rr3.ogg',  note =-15 },
    {path='patches/guitar/a3_f_rr3.ogg',  note = -3 },
    {path='patches/guitar/a4_f_rr3.ogg',  note =  9 },
    {path='patches/guitar/a5_f_rr3.ogg',  note = 21 },
    {path='patches/guitar/c3_f_rr3.ogg',  note =-12 },
    {path='patches/guitar/c4_f_rr3.ogg',  note =  0 },
    {path='patches/guitar/c5_f_rr3.ogg',  note = 12 },
    {path='patches/guitar/c6_f_rr3.ogg',  note = 24 },
    {path='patches/guitar/d6_f_rr3.ogg',  note = 26 },
    {path='patches/guitar/e2_f_rr3.ogg',  note =-20 },
    {path='patches/guitar/db2_f_rr3.ogg', note =-23 },
    {path='patches/guitar/eb3_f_rr3.ogg', note = -9 },
    {path='patches/guitar/eb4_f_rr3.ogg', note =  3 },
    {path='patches/guitar/eb5_f_rr3.ogg', note = 14 },
    {path='patches/guitar/gb2_f_rr3.ogg', note =-18 },
    {path='patches/guitar/gb3_f_rr3.ogg', note = -6 },
    {path='patches/guitar/gb4_f_rr3.ogg', note =  6 },
    {path='patches/guitar/gb5_f_rr3.ogg', note = 18 },



  lowGain = sampler.new({
    {path='patches/guitar/normJMHigh_40.ogg', note =  40 - 60},
    {path='patches/guitar/normJMHigh_43.ogg', note =  43 - 60},
    {path='patches/guitar/normJMHigh_46.ogg', note =  46 - 60},
    {path='patches/guitar/normJMHigh_49.ogg', note =  49 - 60},
    {path='patches/guitar/normJMHigh_52.ogg', note =  52 - 60},
    {path='patches/guitar/normJMHigh_55.ogg', note =  55 - 60},
    {path='patches/guitar/normJMHigh_58.ogg', note =  58 - 60},
    {path='patches/guitar/normJMHigh_61.ogg', note =  61 - 60},
    {path='patches/guitar/normJMHigh_64.ogg', note =  64 - 60},
    {path='patches/guitar/normJMHigh_67.ogg', note =  67 - 60},
    {path='patches/guitar/normJMHigh_70.ogg', note =  70 - 60},
    {path='patches/guitar/normJMHigh_73.ogg', note =  73 - 60},
    {path='patches/guitar/normJMHigh_76.ogg', note =  76 - 60},
    {path='patches/guitar/normJMHigh_79.ogg', note =  79 - 60},
    {path='patches/guitar/normJMHigh_82.ogg', note =  82 - 60},
    {path='patches/guitar/normJMMed_40.ogg', note =  40 - 60},
    {path='patches/guitar/normJMMed_43.ogg', note =  43 - 60},
    {path='patches/guitar/normJMMed_46.ogg', note =  46 - 60},
    {path='patches/guitar/normJMMed_49.ogg', note =  49 - 60},
    {path='patches/guitar/normJMMed_52.ogg', note =  52 - 60},
    {path='patches/guitar/normJMMed_56.ogg', note =  56 - 60},
    {path='patches/guitar/normJMMed_59.ogg', note =  59 - 60},
    {path='patches/guitar/normJMMed_62.ogg', note =  62 - 60},
    {path='patches/guitar/normJMMed_65.ogg', note =  65 - 60},
    {path='patches/guitar/normJMMed_68.ogg', note =  68 - 60},
    {path='patches/guitar/normJMMed_71.ogg', note =  71 - 60},
    {path='patches/guitar/normJMMed_74.ogg', note =  74 - 60},
    {path='patches/guitar/normJMMed_77.ogg', note =  77 - 60},
    {path='patches/guitar/normJMMed_80.ogg', note =  80 - 60},
    {path='patches/guitar/normJMMed_83.ogg', note =  83 - 60},
    {path='patches/guitar/normJMMuted_40.ogg', note =  40 - 60},
    {path='patches/guitar/normJMMuted_43.ogg', note =  43 - 60},
    {path='patches/guitar/normJMMuted_46.ogg', note =  46 - 60},
    {path='patches/guitar/normJMMuted_49.ogg', note =  49 - 60},
    {path='patches/guitar/normJMMuted_52.ogg', note =  52 - 60},
    {path='patches/guitar/normJMMuted_55.ogg', note =  55 - 60},
    {path='patches/guitar/normJMMuted_58.ogg', note =  58 - 60},
    {path='patches/guitar/normJMMuted_61.ogg', note =  61 - 60},
    {path='patches/guitar/normJMMuted_64.ogg', note =  64 - 60},
    {path='patches/guitar/normJMMuted_67.ogg', note =  67 - 60},
    {path='patches/guitar/normJMMuted_70.ogg', note =  70 - 60},
    {path='patches/guitar/normJMMuted_73.ogg', note =  73 - 60},
    {path='patches/guitar/normJMMuted_76.ogg', note =  76 - 60},
    {path='patches/guitar/normJMMuted_79.ogg', note =  79 - 60},
    {path='patches/guitar/normJMMuted_82.ogg', note =  82 - 60},
--]]