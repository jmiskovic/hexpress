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
  background = {l.rgba(0xffffffff)},
  highlight  = {l.hsl(0.88, 0.56, 0.46)},
  surface    = {l.hsl(0.66, 0.25, 0.26)},
  surfaceC   = {l.hsl(0.66, 0.20, 0.23)},
  knob       = {l.hsl(0.67, 0.09, 0.15)},
  text       = {l.hsl(0.66, 0.18, 0.38)},
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

local keyCenter = 0
local noteTracker = {}       -- seconds since last note trigger, across octaves
local noteOctaveTracker = {10,10,10,10,10,10,10,10,10,10,10,10} -- seconds since last note trigger, flattened to single octave
noteOctaveTracker[0] = 10


function patch.load()
  local self = setmetatable({}, patch)

  self.layout = hexpad.new(true)

  self.sampler = sampler.new({
    {path='patches/wurl/wurl_a0.ogg', note = notes.toIndex['A0']},
    {path='patches/wurl/wurl_a1.ogg', note = notes.toIndex['A1']},
    {path='patches/wurl/wurl_a2.ogg', note = notes.toIndex['A2']},
    {path='patches/wurl/wurl_a3.ogg', note = notes.toIndex['A3']},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.15 },
    transpose = -24,
    synthCount = 6,
    })
  self.efx = efx.load()
  self.efx:addEffect(self.efx.tremolo)
  self.efx:setDryVolume(0.4)
  self.efx.reverb.volume = 0.2
  self.efx.reverb.decaytime = 4
  self.efx.tremolo.volume = 0.25
  self.efx.tremolo.frequency = 3

  self.layout.colorScheme.background = colorScheme.background
  self.layout.colorScheme.highlight  = colorScheme.highlight
  self.layout.colorScheme.surface    = colorScheme.surface
  self.layout.colorScheme.surfaceC   = colorScheme.surfaceC
  self.layout.colorScheme.text       = colorScheme.text
  self.layout.drawCell = patch.drawCell
  love.graphics.setBackgroundColor(colorScheme.background)
  return self
end

function patch.drawCell(self, q, r, s, touch)
  local note = self:toNoteIndex(q, r)
  love.graphics.scale(.90)

  local noteTime = noteOctaveTracker[note % 12] -- time since last triggered
  local nh, ns, nl = unpack(colorScheme.noteColors[math.floor(note-keyCenter+.5) % 12 + 1])
  local noteDecay = 10
  local ch, cs, cl

  if s.tilt[1] > .9 and note ~= keyCenter then
    ch, cs, cl = .0, .1, 0.9
  else
    ch, cs = nh, ns
    cl = l.remap(noteTime, noteDecay * 0.9, noteDecay, nl, 1, 'clamp')
  end

  love.graphics.setColor(l.hsl(ch, cs, cl))
  love.graphics.push()

  local freq = 40
  local ampl = l.remap(noteTime, 0, 1, math.pi/12, 0, 'clamp')
  --love.graphics.scale(0.1)
  local scl = 0.3
  if (noteTracker[note] or math.huge) / noteDecay < 1 then
    scl = 0.9
  elseif ((noteTracker[note + 12] or math.huge) / noteDecay < 1
       or (noteTracker[note - 12] or math.huge) / noteDecay < 1) then
    scl = 0.7
  elseif ((noteTracker[note + 24] or math.huge) / noteDecay < 1
       or (noteTracker[note - 24] or math.huge) / noteDecay < 1) then
    scl = 0.5
  end
  scl = scl + ampl / 8 * math.sin(freq * noteTime)
  scl = l.remap(noteTime, 0, 0.1, 0.6, scl, 'clamp')
  --love.graphics.rotate(ampl * math.sin(freq * noteTime))
  love.graphics.scale(scl)
  love.graphics.circle('fill', 0, 0, 0.93, 6) --love.mouse.getY() / love.graphics.getHeight() * 2
  love.graphics.pop()
  if self.displayNoteNames then
    -- note name text
    love.graphics.scale(0.01)
    local text = notes.toName[note % 12]
    love.graphics.setFont(self.font)
    local h = self.font:getHeight()
    local w = self.font:getWidth(text)
    local tl = (cl + 0.5) % 1
    love.graphics.setColor(l.hsl(nh, ns, tl))
    love.graphics.print(text, -w / 2, -h / 2)
  end
end

function patch:process(s)
  self.layout:interpret(s)
  for _,touch in pairs(s.touches) do
    if touch.noteRetrigger then
      noteOctaveTracker[touch.note  % 12] = 0
      noteTracker[touch.note] = 0
    end
    if s.tilt[1] > .9 then
      keyCenter = touch.note or 0
    end
  end

  self.efx.tremolo.frequency = l.remap(s.tilt.lp[1], -0.2, 0.2, 0, 5, 'clamp')
  self.sampler.envelope.attack = l.remap(s.tilt.lp[2], -.1, -0.3, 0, 0.8, 'clamp')
  self.efx:process()

  self.sampler:processTouches(s.dt, s.touches, self.efx)

  for note,decay in pairs(noteTracker) do
    noteTracker[note] = decay + s.dt
  end
  for note,decay in pairs(noteOctaveTracker) do
    noteOctaveTracker[note] = decay + s.dt
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
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  local i = 1
  for q, r in hexgrid.spiralIter(0, 0, 2) do
    -- simulate random notes on grid
    if i == math.floor(q * 29327 + r * 95479 + time) % 19 then
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
      love.graphics.circle('fill', x, y, 1.8 * size, 6)
    love.graphics.pop()
    i = i + 1
  end
end

return patch
