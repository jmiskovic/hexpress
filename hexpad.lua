local hexpad = {}
hexpad.__index = hexpad
local hexgrid = require('hexgrid')
local notes = require('notes')
local l = require('lume')
require('autotable')

hexpad.shape = hexgrid.shape
hexpad.font = love.graphics.newFont("Ubuntu-B.ttf", 64)

local touchToQR = {}

-- create new hexagonal keyboard with following customizations:
--  displayNoteNames: pass true to display note name on each hex, false to hide them
--  noteOffset: transpose all notes by this offset, pass 0 to set center note to C4
--  radius: number of hexes in keyboard measured as maximum hex distance from central hex
function hexpad.new(displayNoteNames, noteOffset, radius)
  local self = setmetatable({
       -- defaults start with C on center of screen and fill whole screen with cells of size
       noteOffset = noteOffset or 4,  -- it's nice to have note E in the centre
       displayNoteNames = displayNoteNames or false,
       colorScheme = {
        surface       = {l.hsl(0.67, 0.11, 0.25)},
        surfaceC      = {l.hsl(0.67, 0.08, 0.23)},
        background    = {l.hsl(0.68, 0.12, 0.31)},
        highlight     = {l.hsl(0.05, 0.72, 0.58)},
        text          = {l.hsl(0.68, 0.12, 0.31)},
      },
    }, hexpad)
  -- would like to keep cell size constant across different devices, so have to
  -- account for resolution and dpi (pixel density)
  self.scaling = 1 / 4.3
  -- this is good enough estimate of radius needed to just fill the screen
  self.radius = radius or math.floor(1 / self.scaling + 2)
  love.graphics.setBackgroundColor(self.colorScheme.background)
  return self
end

-- convert touches into notes
function hexpad:interpret(s)
    -- apply hex grid to find out coordinates and desired note pitch
  for id, touch in pairs(s.touches) do
    local x, y = unpack(touch)

    love.graphics.push()
      love.graphics.scale(self.scaling)
      x, y = love.graphics.inverseTransformPoint(x, y)
    love.graphics.pop()
    local q, r = hexgrid.pixelToHex(x, y)
    if hexgrid.distanceFromCenter(q, r) <= self.radius then
      local noteIndex = self:toNoteIndex(q, r)
      touch.qr       = {q, r}
      touch.location = {x * 0.2, y * 0.2}
      touch.note     = noteIndex
      touch.noteName = notes.toName[noteIndex % 12]
      -- retrigger note if it's new touch or if existing touch has crossed into another cell
      if touchToQR[id] and touchToQR[id][1] == q and touchToQR[id][2] == r then
        touch.noteRetrigger = false
        --touch.duration = s.time - touchToQR[id].startTime
        touchToQR[id][1], touchToQR[id][2] = touch.qr[1], touch.qr[2]
      else
        touch.noteRetrigger = true
        --touch.duration = 0
        touchToQR[id] = touch.qr
        touchToQR[id].startTime = s.time
      end
    end
  end

  -- clean up perished touches
  for id, qr in pairs(touchToQR) do
    local touch = s.touches[id]
    if not touch then
      touchToQR[id] = nil
    end
  end

  return s
end

-- default drawing method that renders hexes and optionally note names
function hexpad:draw(s)
  -- prepare touches for visualization
  local touches = table.autotable(2)
  for id, touch in pairs(s.touches) do
    if touch.qr then
      local q, r = unpack(touch.qr)
      touches[q][r] = touch
    end
  end

  for q, r in hexgrid.spiralIter(0, 0, self.radius) do
    love.graphics.push()
      love.graphics.scale(self.scaling)
      local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.translate(x,y)
      self:drawCell(q, r, s, touches[q][r])
    love.graphics.pop()
  end
end

function hexpad:drawCell(q, r, s, touch)
  local note = self:toNoteIndex(q, r)
  -- shape
  love.graphics.scale(0.90)
  if note % 12 == 0 then
    love.graphics.setColor(self.colorScheme.surfaceC)
  else
    love.graphics.setColor(self.colorScheme.surface)
  end
  if touch and touch.volume then
    love.graphics.scale(1 + touch.volume/10)
    self.colorScheme.highlight[4] = l.remap(touch.volume, 0, 1, 0.1, 1)
    love.graphics.setColor(self.colorScheme.highlight)
  end
  love.graphics.polygon('fill', self.shape)
  if self.displayNoteNames then
    -- note name text
    love.graphics.scale(0.01)
    local text = notes.toName[note % 12]
    love.graphics.setFont(self.font)
    local h = self.font:getHeight()
    local w = self.font:getWidth(text)
    love.graphics.setColor(self.colorScheme.text)
    love.graphics.print(text, -w / 2, -h / 2)
  end
end

function hexpad:toNoteIndex(q, r)
  -- harmonic table layout is defined by two neighbor interval jumps:
  --  +4 semitones when going in NE direction (direction index 1)
  --  +7 semitones when going in N  direction (direction index 2)
  -- the rest of intervals follow from these two
  local intervalNE = 4
  local intervalN  = 7
  return self.noteOffset + q * intervalNE + (-q - r) * intervalN
end

return hexpad
