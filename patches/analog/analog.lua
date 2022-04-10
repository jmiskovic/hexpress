local patch = {}
patch.__index = patch
local l = require('lume')
local efx = require('efx')
local notes = require('notes')

local sampler = require('sampler')
local hexpad = require('hexpad')
local hexgrid = require('hexgrid')

local colorScheme = {
  background = {l.hsl(0.21, 0.13, 0.28)},
  text       = {l.hsl(0.19, 0.26, 0.45)},
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
  local self = setmetatable({}, patch)
  self.layout = hexpad.new(true)

  self.melanc_synth = sampler.new({
    -- BPB mini analogue collection from bedroomproducersblog.com
    {path='patches/analog/mela_c2.ogg',  note = notes.toIndex['C3']},
    {path='patches/analog/mela_c3.ogg',  note = notes.toIndex['C4']},
    {path='patches/analog/mela_c4.ogg',  note = notes.toIndex['C5']},
  })
  self.sawsaw_synth = sampler.new({
    -- ZynAddSubFx patch AnalogStrings
    {path='patches/analog/saw_c1.ogg', note = notes.toIndex['C1']},
    {path='patches/analog/saw_c2.ogg', note = notes.toIndex['C2']},
    {path='patches/analog/saw_c3.ogg', note = notes.toIndex['C3']},
    transpose = -24,
  })
  self.efx = efx.load()
  self.efx.reverb.decaytime = 2

  self.layout.colorScheme.background = colorScheme.background
  self.layout.colorScheme.highlight  = colorScheme.highlight
  self.layout.colorScheme.surface    = colorScheme.surface
  self.layout.colorScheme.surfaceC   = colorScheme.surfaceC
  self.layout.colorScheme.text       = colorScheme.text

  self.layout.drawCell=function(self, q, r, s, touch)
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
      love.graphics.polygon('fill', hexgrid.hexagon)
      love.graphics.pop()
    end
    love.graphics.pop()
    love.graphics.setColor(self.colorScheme.surface)
    love.graphics.polygon('fill', hexgrid.hexagon)
  end
  love.graphics.setBackgroundColor(colorScheme.background)
  return self
end

function patch:process(s)
  self.layout:interpret(s)
  self.melanc_synth.masterVolume = l.remap(s.tilt.lp[1],  0.2,  0.0, 0, 1, 'clamp')
  self.sawsaw_synth.masterVolume = l.remap(s.tilt.lp[2],  0.0,  0.7, 0, 1, 'clamp')
  self.efx:process()
  self.melanc_synth:processTouches(s.dt, s.touches, self.efx)
  self.sawsaw_synth:processTouches(s.dt, s.touches, self.efx)
end

function patch:draw(s)
  self.layout:draw(s)
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
  love.graphics.rectangle('fill', -2, -2, 4, 4)
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
