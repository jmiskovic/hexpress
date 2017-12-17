local patch = {}

local l = require('lume')
local efx = require('efx')
local notes = require('notes')

local sampler = require('sampler')
local hexpad = require('hexpad')


local colorScheme = {
  background = {l.hsl(0.21, 0.13, 0.28)},
  bright     = {l.hsl(0.19, 0.26, 0.45)},
  highlight  = {l.hsl(0.04, 0.63, 0.50)},
  surface    = {l.hsl(0.20, 0.48, 0.63)},
  surfaceC   = {l.hsl(0.20, 0.30, 0.50)},
  grid       = {l.hsl(0.20, 0.48, 0.85, 0.2)},
  beam       = {l.hsl(0.20, 0.48, 0.85)},
}

local filter = {
  volume   = 1.0,
  type     = 'lowpass',
  highgain = 0.5,
}

local chorus_synth, melanc_synth, sawsaw_synth

function patch.load()
  keyboard = hexpad.new()
  efx.reverb.decaytime = 2

  chorus_synth = sampler.new({
    -- BPB mini analogue collection from bedroomproducersblog.com
    {path='patches/analog/chorus_c1.ogg', note = notes.toIndex['C1']},
    {path='patches/analog/chorus_c2.ogg', note = notes.toIndex['C2']},
    {path='patches/analog/chorus_c3.ogg', note = notes.toIndex['C3']},
    {path='patches/analog/chorus_c4.ogg', note = notes.toIndex['C4']},
    transpose = -24,
    envelope = { attack = 0.0, decay = 0, sustain = 1, release = 0.35 },
  })
  melanc_synth = sampler.new({
    -- BPB mini analogue collection from bedroomproducersblog.com
    {path='patches/analog/mela_c2.ogg',  note = notes.toIndex['C3']},
    {path='patches/analog/mela_c3.ogg',  note = notes.toIndex['C4']},
    {path='patches/analog/mela_c4.ogg',  note = notes.toIndex['C5']},
  })
  sawsaw_synth = sampler.new({
    -- ZynAddSubFx patch AnalogStrings
    {path='patches/analog/saw_c1.ogg', note = notes.toIndex['C1']},
    {path='patches/analog/saw_c2.ogg', note = notes.toIndex['C2']},
    {path='patches/analog/saw_c3.ogg', note = notes.toIndex['C3']},
    transpose = -24,
  })
  keyboard.colorScheme.background = colorScheme.background
  keyboard.colorScheme.highlight  = colorScheme.highlight
  keyboard.colorScheme.surface    = colorScheme.surface
  keyboard.colorScheme.surfaceC   = colorScheme.surfaceC
  keyboard.colorScheme.bright     = colorScheme.bright
  love.graphics.setBackgroundColor(colorScheme.background)
end

function patch.process(s)
  keyboard:interpret(s)
  chorus_synth.masterVolume = l.remap(s.tilt.lp[1], -0.1,  0.0, 0, 1, 'clamp')
  melanc_synth.masterVolume = l.remap(s.tilt.lp[1],  0.1,  0.0, 0, 1, 'clamp')
  sawsaw_synth.masterVolume = l.remap(s.tilt.lp[2], 0.7, 0.2, 1, 0, 'clamp')
  chorus_synth:update(s.dt, s.touches)
  melanc_synth:update(s.dt, s.touches)
  sawsaw_synth:update(s.dt, s.touches)
end

function patch.draw(s)
  keyboard:draw(s)
end

local sine = {}
for x = -2, 1, 0.02 do
  table.insert(sine, x)
  table.insert(sine,
    2 / math.pi * (math.sin(2 * x * math.pi) + 1 / 3 * math.sin(6 * x * math.pi)))
  --table.insert(sine, math.sin(2 * x * math.pi))
end

function patch.icon(time)
  love.graphics.setColor(colorScheme.surfaceC)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  love.graphics.setColor(colorScheme.grid)
  love.graphics.setLineWidth(0.001)
  for x = -1, 1, 0.5 do
    love.graphics.line(x, -1, x, 1)
  end
  for y = -1, 1, 0.5 do
    love.graphics.line(-1, y, 1, y)
  end
  love.graphics.setColor(colorScheme.beam)
  love.graphics.setLineWidth(0.06)
  love.graphics.translate(time % 1, 0)
  love.graphics.line(sine)
end

return patch
