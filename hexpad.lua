local hexpad = {}
hexpad.__index = hexpad
local hexgrid = require('hexgrid')
local l = require('lume')
require('autotable')

hexpad.shape = hexgrid.shape
hexpad.font = love.graphics.newFont("Ubuntu-B.ttf", 64)
hexpad.noteIndexToName = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}

hexpad.colorScheme = {
  background    = {l.rgba(0x2d2734ff)},
  highlight     = {l.rgba(0xe86630ff)},
  surface       = {l.rgba(0x687591ff)},
  bright        = {l.rgba(0xa7a2b8ff)},
}

local touchToQR = {}

function hexpad.new(noteOffset, radius)
  local self = setmetatable({
       -- defaults start with C on center of screen and fill whole screen with cells of size
       noteOffset = noteOffset or 4,  -- it's nice to have note E in the centre
    }, hexpad)
  -- would like to keep cell size constant across different devices, so have to
  -- account for resolution and dpi (pixel density)
  self.scaling = 1 / 4.3
  -- this is good enough estimate of radius needed to just fill the screen
  self.radius = radius or math.floor(1 / self.scaling + 2)
  love.graphics.setBackgroundColor(self.colorScheme.background)
  return self
end

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
      local noteIndex = self:hexToNoteIndex(q, r)
      touch.qr       = {q, r}
      touch.note     = noteIndex
      touch.noteName = self.noteIndexToName[noteIndex % 12 + 1]
      -- retrigger note if it's new touch or if existing touch has crossed into another cell
      if touchToQR[id] and touchToQR[id][1] == q and touchToQR[id][2] == r then
        touch.noteRetrigger = false
        touch.duration = s.time - touchToQR[id].startTime
        touchToQR[id][1], touchToQR[id][2] = touch.qr[1], touch.qr[2]
      else
        touch.noteRetrigger = true
        touch.duration = 0
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
  -- shape
  love.graphics.scale(0.90)
  love.graphics.setColor(self.colorScheme.surface)
  love.graphics.polygon('fill', self.shape)
  if touch and touch.volume then
    love.graphics.scale(1 + touch.volume/10)
    self.colorScheme.highlight[4] = l.remap(touch.volume, 0, 1, 0.1, 1)
    love.graphics.setColor(self.colorScheme.highlight)
    love.graphics.polygon('fill', self.shape)
  end
  -- note name text
  love.graphics.scale(0.01)
  local note = self:hexToNoteIndex(q, r)
  local text = self.noteIndexToName[note % 12 + 1]
  love.graphics.setFont(self.font)
  local h = self.font:getHeight()
  local w = self.font:getWidth(text)
  love.graphics.setColor(self.colorScheme.bright)
  love.graphics.print(text, -w / 2, -h / 2) -- +5, because of some obscure getWidth() bug
end

function hexpad:hexToNoteIndex(q, r)
  -- harmonic table layout is defined by two neighbor interval jumps:
  --  +4 semitones when going in NE direction (direction index 1)
  --  +7 semitones when going in N  direction (direction index 2)
  -- the rest of intervals follow from these two
  local intervalNE = 4
  local intervalN  = 7
  return self.noteOffset + q * intervalNE + (-q - r) * intervalN
end

return hexpad