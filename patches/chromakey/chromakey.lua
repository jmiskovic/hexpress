local patch = {}
patch.__index = patch

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

patch.name = 'chormakey'

function patch.load()
  local self = setmetatable({}, patch)
  self.layout = hexpad.new(true)
  self.synth = sampler.new({
    {path='patches/chromakey/synthpad.ogg',  note= notes.toIndex['C3']},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.15 },
    synthCount = 10,
    transpose = -24,
    })
  self.sustain = sampler.new({
    {path='patches/chromakey/sustain.ogg',  note= notes.toIndex['C5']},
    envelope = { attack = 6, decay = 0, sustain = 1, release = 0.15 },
    looped = true,
    synthCount = 10,
    })
  self.efx = efx.load()
  self.efx:addEffect(self.efx.tremolo)
  self.efx:setDryVolume(0.4)
  self.efx.reverb.decaytime = 1.5

  self.layout.colorScheme.background = colorScheme.background
  self.layout.colorScheme.highlight  = colorScheme.highlight
  self.layout.colorScheme.surface    = colorScheme.surface
  self.layout.colorScheme.surfaceC   = colorScheme.surfaceC
  self.layout.colorScheme.text       = colorScheme.text
  love.graphics.setBackgroundColor(colorScheme.background)
  self.layout.drawCell = patch.drawCell
  return self
end


-- override the hexpad's drawCell but still reuse it's layouting
function patch.drawCell(self, q, r, s, touch)
  local ch, cs, cl
  local note = self:toNoteIndex(q, r)
  love.graphics.scale(.90)
  if s.tilt[1] > .9 and note ~= keyCenter then
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


function patch:process(s)
  self.layout:interpret(s)
  -- track pressed notes for visualization
  for _,touch in pairs(s.touches) do
    if touch.noteRetrigger then
      noteTracker[touch.note  % 12] = (noteTracker[touch.note % 12] or 0) + 20000
    end
    if s.tilt[1] > .9 then
      keyCenter = touch.note or 0
    end
  end

  self.synth.masterVolume = l.remap(s.tilt[2], 0.2, 0.7, 0.2, 1, 'clamp')
  self.sustain.masterVolume = l.remap(s.tilt[2], 0.2, 0.7, 0.2, 1, 'clamp')

  self.efx.tremolo.frequency = l.remap(s.tilt.lp[1], 0.05, 0.3, 0, 8, 'clamp')
  self.efx.tremolo.volume = l.remap(s.tilt.lp[1], 0, 1, 0, 0.9, 'clamp')
  self.efx:process(s)

  self.synth:processTouches(s.dt, s.touches, self.efx)
  self.sustain:processTouches(s.dt, s.touches, self.efx)

  -- slowly forget pressed notes
  for note,decay in pairs(noteTracker) do
    noteTracker[note] = decay * (1 - s.dt * 1)
  end
end


function patch:draw(s)
  self.layout:draw(s)
end


local iconDecay = {}
local i = 1
for q, r in hexgrid.spiralIter(0, 0, 2) do
  iconDecay[i] = -10
  i = i + 1
end


function patch.icon(time)
  love.graphics.setColor(colorScheme.background)
  love.graphics.rectangle('fill', -2, -2, 4, 4)
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
