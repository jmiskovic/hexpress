local patch = {}

local l = require('lume')
local efx = require('efx')
local notes = require('notes')

local sampler = require('sampler')
local hexpad = require('hexpad')
local hexgrid = require('hexgrid')

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

function patch.load()
  patch.keyboard = hexpad.new(true)
  if love.system.getOS() == 'Android' then
    efx.setDryVolume(0.2)
    efx.addEffect(efx.wah)
  end
  efx.reverb.decaytime = 2

  patch.chorus_synth = sampler.new({
    -- BPB mini analogue collection from bedroomproducersblog.com
    {path='patches/analog/chorus_c1.ogg', note = notes.toIndex['C1']},
    {path='patches/analog/chorus_c2.ogg', note = notes.toIndex['C2']},
    {path='patches/analog/chorus_c3.ogg', note = notes.toIndex['C3']},
    {path='patches/analog/chorus_c4.ogg', note = notes.toIndex['C4']},
    transpose = -24,
    envelope = { attack = 0.0, decay = 0, sustain = 1, release = 0.35 },
  })
  patch.melanc_synth = sampler.new({
    -- BPB mini analogue collection from bedroomproducersblog.com
    {path='patches/analog/mela_c2.ogg',  note = notes.toIndex['C3']},
    {path='patches/analog/mela_c3.ogg',  note = notes.toIndex['C4']},
    {path='patches/analog/mela_c4.ogg',  note = notes.toIndex['C5']},
  })
  patch.sawsaw_synth = sampler.new({
    -- ZynAddSubFx patch AnalogStrings
    {path='patches/analog/saw_c1.ogg', note = notes.toIndex['C1']},
    {path='patches/analog/saw_c2.ogg', note = notes.toIndex['C2']},
    {path='patches/analog/saw_c3.ogg', note = notes.toIndex['C3']},
    transpose = -24,
  })
  patch.keyboard.colorScheme.background = colorScheme.background
  patch.keyboard.colorScheme.highlight  = colorScheme.highlight
  patch.keyboard.colorScheme.surface    = colorScheme.surface
  patch.keyboard.colorScheme.surfaceC   = colorScheme.surfaceC
  patch.keyboard.colorScheme.bright     = colorScheme.bright
  love.graphics.setBackgroundColor(colorScheme.background)

  function patch.keyboard:drawCell(q, r, s, touch)
    love.graphics.scale(0.70)

    local expandTo = expandTo or 1.02
    local slices = 4
    local fraction = (expandTo - 1) / slices

    local color = self.colorScheme.surfaceC
    love.graphics.push()
    if touch and touch.volume then
      color = self.colorScheme.highlight
      love.graphics.scale(1 + touch.volume/10)
    end

    for slice = 2, slices do
      love.graphics.push()
      local sX = 2600 * (slice - 1) * fraction   -- sX and sY define distance from center
      local sY = 1600 * (slice - 1) * fraction
      if expandTo < 1 then
        sY = -sY
        sX = -sX
      end
      local x = fraction * l.remap(s.tilt.lp[1], -.30,  .30, sX, -sX)
      local y = fraction * l.remap(s.tilt.lp[2],  .80,  .5, -sY,  sY)
      local s = l.remap(slice, 1, slices, 1, expandTo)

      color[4] = math.exp(-2.5 * (slice - 1) /slices)
      love.graphics.setColor(color)
      love.graphics.scale(s)
      love.graphics.translate(x, y)
      love.graphics.setLineWidth(1/6)
      love.graphics.polygon('fill', hexgrid.shape)
      love.graphics.pop()
    end
    love.graphics.pop()
    love.graphics.setColor(self.colorScheme.surface)
    love.graphics.polygon('fill', self.shape)
  end

end

function patch.process(s)
  patch.keyboard:interpret(s)
  patch.chorus_synth.masterVolume = l.remap(s.tilt.lp[1], -0.1,  0.0, 0, 1, 'clamp')
  patch.melanc_synth.masterVolume = l.remap(s.tilt.lp[1],  0.1,  0.0, 0, 1, 'clamp')
  patch.sawsaw_synth.masterVolume = l.remap(s.tilt.lp[2], 0.7, 0.2, 1, 0, 'clamp')
  efx.wah.position = l.remap(math.abs(s.tilt[2]), 0.7, 0, 0.3, 1.0, 'clamp')

  patch.chorus_synth:processTouches(s.dt, s.touches)
  patch.melanc_synth:processTouches(s.dt, s.touches)
  patch.sawsaw_synth:processTouches(s.dt, s.touches)
end

function patch.draw(s)
  patch.keyboard:draw(s)
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
