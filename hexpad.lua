hexpad = {}
hexpad.__index = hexpad

local hexgrid = require('hexgrid')

local noteIndexToName = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
local touchToQR = {}

function hexpad.new(noteOffset, cellSize, radius, cx, cy)
  local self = setmetatable({
       -- defaults start with C on center of screen and fill whole screen with cells of size
       cx       = cx or love.graphics.getWidth()  / 2,
       cy       = cy or love.graphics.getHeight() / 2,
       cellSize = cellSize or 80,
       noteOffset = noteOffset or 0,
    }, hexpad)
  -- this is good enough estimate of radius needed to just fill the screen
  self.radius = radius or math.floor(self.cx / self.cellSize) - 2
  return self
end

function hexpad:interpret(stream)
    -- apply hex grid to find out coordinates and desired note pitch
  for id, touch in pairs(stream.touches) do
    local x, y = unpack(touch)
    local q, r = hexgrid.pixelToHex(x, y, self.cx, self.cy, self.cellSize)
    if hexgrid.distanceFromCenter(q, r) <= self.radius then
      local noteIndex = self:hexToNoteIndex(q, r)
      touch.qr = {q, r}
      touch.note     = noteIndex
      touch.noteName = noteIndexToName[noteIndex % 12 + 1]
      -- retrigger note if it's new touch or if existing touch has crossed into another cell
      touch.noteRetrigger = not touchToQR[id] or (touchToQR[id][1] ~= q or touchToQR[id][2] ~= r)
      touchToQR[id] = touch.qr -- store touch qr for next iteration
    end
  end

  -- clean up perished touches
  for id, qr in pairs(touchToQR) do
    local touch = stream.touches[id]
    if not touch then
      touchToQR[id] = nil
    end
  end

  return stream
end

function hexpad:draw(drawCellFunc)
  drawCellFunc = drawCellFunc or hexpad.drawCell
  love.graphics.setColor(0.2,0.2,0.9)
  for q, r in hexgrid.spiralIter(0, 0, self.radius) do
    local x, y = hexgrid.hexToPixel(q, r, self.cx, self.cy, self.cellSize)
    love.graphics.translate(x,y)
    love.graphics.scale(self.cellSize * 0.9)
    drawCellFunc(q, r)
    love.graphics.origin()
  end
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

function hexpad.drawCell(q, r)
  love.graphics.polygon('fill', hexgrid.shape)
end

return hexpad