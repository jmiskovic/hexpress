local patch = {}

local l = require('lume')
local efx = require('efx')

local notes = require('notes')
local sampler = require('sampler')
local hexpad = require('hexpad')
local hexgrid = require('hexgrid')
local controls = require('controls')

local colorScheme = {
  background = {l.rgba(0x0a0a0cff)},
  highlight  = {l.hsl(0.88, 0.56, 0.46)},
  surface    = {l.hsl(0.66, 0.25, 0.26)},
  surfaceC   = {l.hsl(0.66, 0.20, 0.23)},
  knob       = {l.hsl(0.67, 0.09, 0.15)},
  bright     = {l.hsl(0.66, 0.18, 0.38)},
  text       = {l.hsl(0.24, 0.09, 0.72)},
  shiny      = {l.hsl(0.24, 0.09, 0.96, 0.5)},
}

local noteTracker = {}
local keyCenter = 0

function patch.load()
  efx.addEffect(efx.tremolo)
  efx.setDryVolume(0.4)
  efx.reverb.volume = 1
  efx.reverb.decaytime = 2
  efx.tremolo.volume = 1
  efx.tremolo.frequency = 4

  patch.keyboard = hexpad.new(true)

  patch.rhodes = sampler.new({

    {path='patches/chromakey/synthpad.ogg',  note= notes.toIndex['C3']},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.15 },
    synthCount = 10,
    transpose = -24,
    })
  patch.keyboard.colorScheme.background = colorScheme.background
  patch.keyboard.colorScheme.highlight  = colorScheme.highlight
  patch.keyboard.colorScheme.surface    = colorScheme.surface
  patch.keyboard.colorScheme.surfaceC   = colorScheme.surfaceC
  patch.keyboard.colorScheme.bright     = colorScheme.bright
  love.graphics.setBackgroundColor(colorScheme.background)

  patch.keyboard.drawCell = patch.drawCell
end

  function patch.drawCell(self, q, r, s, touch)
  local note = self:toNoteIndex(q, r)
  love.graphics.scale(.90)

  local ch, cs, cl
  local centralHue = .32
  ch = (((note - keyCenter) * 7 + 12 * centralHue) % 12) / 12
  cs = .05 + .45 * (1- math.exp(-(noteTracker[note % 12] or 0)/3))
  cl = .1  + .35 * (1- math.exp(-(noteTracker[note % 12] or 0)/3))

  if touch and touch.volume then
    love.graphics.scale(1 + touch.volume/10)
    cs = cs - touch.volume * 0.5
    cl = cl + touch.volume * 0.5
  end
  love.graphics.setColor(l.hsl(ch, cs, cl))
  love.graphics.circle('fill', 0, 0, 0.8)
  if self.displayNoteNames then
    -- note name text
    love.graphics.scale(0.01)
    local text = notes.toName[note % 12]
    love.graphics.setFont(self.font)
    local h = self.font:getHeight()
    local w = self.font:getWidth(text)
    cl = 1 - cl
    love.graphics.setColor(l.hsl(ch, cs, cl))
    love.graphics.print(text, -w / 2, -h / 2)
  end
end

function patch.process(s)
  patch.keyboard:interpret(s)
  if not s.pressureSupport then
    for _,touch in pairs(s.touches) do
      touch.pressure = l.remap(s.tilt[2], 0.2, 0.7, 0.1, 1, 'clamp')
      if touch.noteRetrigger then
        noteTracker[touch.note  % 12] = (noteTracker[touch.note % 12] or 0) + 1
        if not controls.frozen then
          keyCenter = touch.note
        end
      end
    end
    patch.rhodes.masterVolume = l.remap(s.tilt[2], 0.2, 0.7, 0.2, 1, 'clamp')
  end
  efx.tremolo.frequency = l.remap(s.tilt.lp[1], -0.3, 0.3, 0, 8, 'clamp')
  patch.rhodes:processTouches(s.dt, s.touches)

  for note,decay in pairs(noteTracker) do
    noteTracker[note] = decay * (1 - s.dt * 0.3)
  end
end

function patch.draw(s)
  patch.keyboard:draw(s)
end

function patch.icon(time)
  love.graphics.setColor(colorScheme.surface)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  local i = 0
  for q, r in hexgrid.spiralIter(0, 0, 2) do
    love.graphics.setColor(l.hsl(
      (i / 12 + time/5) % 1,
      0.3,
      0.4
      ))
    love.graphics.push()
    local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.scale(0.15)
      local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.translate(x,y)
      love.graphics.circle('fill', x, y, 1.6)
    love.graphics.pop()
    i = i + 1
  end
end

return patch
