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
  noteColors = {
    {0.42, 0.42, 0.25},
    {0.99, 0.88, 0.71},
    {0.10, 0.99, 0.60},
    {0.58, 0.77, 0.30},
    {0.14, 0.99, 0.69},
    {0.01, 0.34, 0.34},
    {0.99, 0.76, 0.56},
    {0.30, 0.52, 0.54},
    {0.91, 0.41, 0.51},
    {0.06, 0.65, 0.55},
    {0.51, 0.91, 0.57},
    {0.82, 0.32, 0.32},
    --{0.07, 0.64, 0.75},
  },
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

  patch.synth = sampler.new({

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

  if s.tilt[1] > .5 and note ~= keyCenter then
    ch, cs, cl = .0, .1, .1
  else
    ch, cs, cl = unpack(colorScheme.noteColors[math.floor(note-keyCenter+.5) % 12 + 1])
    cl = cl * (1 - math.exp(-(noteTracker[note % 12] or 0)/2))
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
    cl = (cl + 0.5) % 1
    love.graphics.setColor(l.hsl(ch, cs, cl))
    love.graphics.print(text, -w / 2, -h / 2)
  end
end

function patch.process(s)
  patch.keyboard:interpret(s)
  for _,touch in pairs(s.touches) do
    touch.pressure = l.remap(s.tilt[2], 0.2, 0.7, 0.1, 1, 'clamp')
    if touch.noteRetrigger then
      noteTracker[touch.note  % 12] = (noteTracker[touch.note % 12] or 0) + 20000
    end
    if s.tilt[1] > .5 then
      keyCenter = touch.note
    end
  end
  patch.synth.masterVolume = l.remap(s.tilt[2], 0.2, 0.7, 0.2, 1, 'clamp')

  efx.tremolo.frequency = l.remap(s.tilt.lp[1], -0.3, 0.3, 0, 8, 'clamp')
  patch.synth:processTouches(s.dt, s.touches)

  for note,decay in pairs(noteTracker) do
    noteTracker[note] = decay * (1 - s.dt * 1)
  end
end

function patch.draw(s)
  patch.keyboard:draw(s)
end


local iconDecay = {}
local i = 1
for q, r in hexgrid.spiralIter(0, 0, 2) do
  iconDecay[i] = -10
  i = i + 1
end

function patch.icon(time)
  love.graphics.setColor(colorScheme.background)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  local i = 1
  for q, r in hexgrid.spiralIter(0, 0, 2) do
    -- simulate random notes on grid
    if i == math.floor(q * 17293 + r * 13457 + time / 2) % 19 then
      iconDecay[i] = time
    end
    -- note size drops with time
    local size = math.max(.2,  math.exp((iconDecay[i] - time) / 4))

    love.graphics.setColor(l.hsl(
        unpack(colorScheme.noteColors[(i % #colorScheme.noteColors) + 1])
      ))

    love.graphics.push()
    local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.scale(0.15)
      local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.translate(x,y)
      love.graphics.circle('fill', x, y, 1.2 * size)
    love.graphics.pop()
    i = i + 1
  end
end

return patch
