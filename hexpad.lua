hexpad = {}
hexpad.__index = hexpad

local hexgrid = require('hexgrid')

local noteIndexToName = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
local touchToQR = {}

local font = love.graphics.newFont("Ubuntu-B.ttf", 24)

local colorScheme = {
  background   = {0.28, 0.27, 0.35, 1.00},
  padHighlight = {0.96, 0.49, 0.26, 1.00},
  padSurface   = {0.20, 0.20, 0.26, 1.00},
  white        = {1.00, 1.00, 1.00, 1.00},
}


function hexpad.new(noteOffset, cellSize, radius, cx, cy)
  local sw = love.graphics.getWidth()
  local sh = love.graphics.getHeight()
  local self = setmetatable({
       -- defaults start with C on center of screen and fill whole screen with cells of size
       cx       = cx or sw / 2,
       cy       = cy or sh / 2,
       cellSize = cellSize or 40 * sh / 360,
       noteOffset = noteOffset or 0,
    }, hexpad)
  -- this is good enough estimate of radius needed to just fill the screen
  self.radius = radius or math.floor(self.cx / self.cellSize) - 2
  log('screen', self.cx*2, self.cy*2)
  log('radius', self.radius)
  log('cell', self.cellSize)
  return self
end

function hexpad:interpret(s)
    -- apply hex grid to find out coordinates and desired note pitch
  for id, touch in pairs(s.touches) do
    local x, y = unpack(touch)
    local q, r = hexgrid.pixelToHex(x, y, self.cx, self.cy, self.cellSize)
    if hexgrid.distanceFromCenter(q, r) <= self.radius then
      local noteIndex = self:hexToNoteIndex(q, r)
      touch.qr       = {q, r}
      touch.note     = noteIndex
      touch.noteName = noteIndexToName[noteIndex % 12 + 1]
      -- retrigger note if it's new touch or if existing touch has crossed into another cell
      touch.noteRetrigger = not touchToQR[id] or (touchToQR[id][1] ~= q or touchToQR[id][2] ~= r)
      touchToQR[id] = touch.qr -- store touch qr for next iteration
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
  for q, r in hexgrid.spiralIter(0, 0, self.radius) do
    local x, y = hexgrid.hexToPixel(q, r, self.cx, self.cy, self.cellSize)
    love.graphics.translate(x,y)
    love.graphics.scale(self.cellSize)
    self:drawCell(q, r, s)
    love.graphics.scale(1/self.cellSize)
    love.graphics.origin()
  end
  if s.touches then
    for id, touch in pairs(s.touches) do
      local x, y = hexgrid.hexToPixel(touch.qr[1], touch.qr[2], self.cx, self.cy, self.cellSize)
      love.graphics.translate(x,y)
      love.graphics.scale(self.cellSize)
      hexpad:drawTouch(touch, s)
      love.graphics.scale(1 / self.cellSize)
      love.graphics.origin()
    end
  end
end

function hexpad:drawCell(q, r, s)
  -- shape
  love.graphics.setColor(colorScheme.padSurface)
  love.graphics.push()
  love.graphics.scale(0.90)
  love.graphics.polygon('fill', hexgrid.shape)
  love.graphics.setColor(colorScheme.background)
  -- note name text
  local note = self:hexToNoteIndex(q, r)
  local text = noteIndexToName[note % 12 + 1]
  love.graphics.setFont(font)
  local h = font:getHeight()
  local w = font:getHeight()
  love.graphics.scale(0.03)
  love.graphics.print(text, -w / 2 + 5, -h / 2) -- +5, because of some obscure getWidth() bug
  love.graphics.pop()
end

function hexpad:drawTouch(touch, s)
  local size = 0.8
  love.graphics.push()
  -- colorScheme.padHighlight[4] =
  love.graphics.setColor(colorScheme.padHighlight)
  love.graphics.scale(size)
  love.graphics.setLineWidth(1/6)
  love.graphics.polygon('line', hexgrid.shape)
  love.graphics.setColor(colorScheme.background)
  love.graphics.pop()
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