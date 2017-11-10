local honeycomb = {}
honeycomb.__index = honeycomb

local l = require('lume')
require('autotable')
local hexgrid = require('hexgrid')

local synths = require('synths')
local min = math.min
local max = math.max


honeycomb.synth_mapping = {}
honeycomb.font_color = {0.13, 0.13, 0.13, 0.5}
honeycomb.hexapoly = { 1,  0, 1/2, math.sqrt(3)/2, -1/2, math.sqrt(3)/2, -1,  0, -1/2, -math.sqrt(3)/2, 1/2, -math.sqrt(3)/2 }
note_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
honeycomb.note_offset = 4


local scheme = {
  background    = {0.28, 0.27, 0.35, 1.00},
  pad_highlight = {0.96, 0.49, 0.26, 1.00},
  pad_surface   = {0.21, 0.21, 0.27, 1.00},
  white         = {1.00, 1.00, 1.00, 1.00},
}

love.graphics.setBackgroundColor(scheme.background)

-- harmonic note grid from QR coordinate
function hexToNoteMapping(q, r)
    return q*4 + (-q-r)*7 + honeycomb.note_offset
end

-- specify new grid with cell size and grid span ('radius' from center cell)
function honeycomb.new(cx, cy, size, radius)
  local self = setmetatable({}, honeycomb)

  self.size = size or 10
  self.radius = radius or 5
  self.cx, self.cy = cx, cy
  self.font = love.graphics.newFont("Ubuntu-B.ttf", size/2)
  self.touches = {}
  self.predrawnPads = {}
  self.pads = table.autotable(2)

  local id = 1
  for q, r in hexgrid.spiralIter(0, 0, self.radius) do
    self.pads[q][r] = self:newPad(id, q, r)
    id = id + 1
  end
  return self
end

function honeycomb:touchpressed(id, x, y, dx, dy, pressure)
  local q, r = hexgrid.pixelToHex(x, y, self.cx, self.cy, self.size)
  self.touches[id] = {q, r, x, y}
  self:pressedPad(self.pads[q][r])
end

function honeycomb:touchmoved(id, x, y, dx, dy, pressure)
    local q, r = hexgrid.pixelToHex(x, y, self.cx, self.cy, self.size)

    if self.touches[id] then
      if q == self.touches[id][1] and r == self.touches[id][2] then
        -- finger hasn't left the pad
        self:movedPad(dx, dy, self.pads[q][r])
      else
        -- finger has crossed to another pad
        local qp, rp = unpack(self.touches[id]) -- previous pad
        self:releasedPad(self.pads[qp][rp])
        self:pressedPad(self.pads[q][r])
      end
    end
    self.touches[id] = {q, r, x, y}
end

function honeycomb:touchreleased(id, x, y, dx, dy, pressure)
  if self.touches[id] then
    local q, r = unpack(self.touches[id])
    self:releasedPad(self.pads[q][r])
  end
  self.touches[id] = nil
end

function honeycomb:draw()
  for q, r in hexgrid.spiralIter(0, 0, self.radius) do
    if self.pads[q][r] then
      self:drawPad(q, r, self.pads[q][r])
    end
  end
end

function honeycomb:newPad(id, q, r)
  local note = hexToNoteMapping(q, r)
  local pad = {}
  pad.name = note_names[note % 12 +1]
  pad.pitch = math.pow(math.pow(2, 1/12), note)
  pad.id = id
  self.synth_mapping[pad] = nil -- index of selected synth, valid while pad is pressed
  if not self.predrawnPads[pad.name] then
    self.predrawnPads[pad.name] = self:predrawPad(pad.name)
  end
  return pad
end

function honeycomb:predrawPad(text)
  local canvas = love.graphics.newCanvas(self.size * 2, self.size * 2)
  love.graphics.origin()
  love.graphics.setFont(self.font)
  love.graphics.setCanvas(canvas)
  love.graphics.translate(self.size, self.size)
  love.graphics.scale(0.95)
  love.graphics.setColor(scheme.pad_surface)
  love.graphics.scale(self.size)
  love.graphics.polygon('fill', honeycomb.hexapoly)
  love.graphics.origin()
  love.graphics.setColor(scheme.background)
  local width, height = self.font:getWidth(text)/2, self.font:getHeight()
  love.graphics.print(text, self.size - width / 2, self.size - height / 2)
  love.graphics.setCanvas()
  return canvas
end

function honeycomb:drawPad(q, r, pad)
  local image = self.predrawnPads[pad.name]
  local x, y = hexgrid.hexToPixel(q, r, self.cx, self.cy, self.size)
  --log('y %4.3f cy %4.3f  size %4.3f', y, self.cy, self.size)
  love.graphics.translate(x, y)
  local volume = (honeycomb.synth_mapping[pad] and honeycomb.synth_mapping[pad].volume or 0)
  love.graphics.setFont(self.font)
  love.graphics.scale(0.95 + 0.1 * volume)
  love.graphics.setColor(scheme.white)
  love.graphics.draw(image, - image:getWidth() / 2, - image:getHeight() / 2)

  if volume > 0 then
    scheme.pad_highlight[4] = volume
    love.graphics.setColor(scheme.pad_highlight)
    love.graphics.scale(0.8)
    love.graphics.setLineWidth(12 / self.size)
    love.graphics.scale(self.size)
    love.graphics.polygon('line', honeycomb.hexapoly)
  end
  --if instrumentSelect then
  --  love.graphics.scale(0.7)
  --  love.math.setRandomSeed(self.id)
  --  love.graphics.setColor(love.math.random(), love.math.random(), love.math.random(), 0.2)
  --  love.graphics.scale(self.size)
  --  love.graphics.polygon('fill', honeycomb.hexapoly)
  --  if self.id == presetIndex then
  --    scheme.pad_highlight[4] = 0.5
  --    love.graphics.setColor(scheme.pad_highlight)
  --    love.graphics.setLineWidth(16 / self.size)
  --    love.graphics.polygon('line', honeycomb.hexapoly)
  --  end
  --end
  love.graphics.origin()
end

function honeycomb:pressedPad(pad)
  local synth = synths.get_unused()
  -- remove previous association with pad
  for p,s in pairs(honeycomb.synth_mapping) do
    if s == synth then honeycomb.synth_mapping[p] = nil end
  end
  if honeycomb.synth_mapping[pad] then
    self:releasedPad(pad)
  end
  honeycomb.synth_mapping[pad] = synth
  synth:startNote(pad.pitch)
end

function honeycomb:movedPad(dx,dy, pad)
end

function honeycomb:releasedPad(pad)
  if self.synth_mapping[pad] then
    self.synth_mapping[pad]:stopNote()
  end
end

return honeycomb