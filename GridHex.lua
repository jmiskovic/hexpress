local GridHex = {}

GridHex.__index = GridHex

require('autotable')
local pad = require('pad')


-- specify new grid with cell size and grid span ('radius' from center cell)
function GridHex.new(size, radius)
  local self = setmetatable({}, GridHex)
  self.table = table.autotable(2)
  self.size = size or 10
  self.radius = radius or 5
  size = size * 0.95
  pad.hexapoly = {
      size,          0,
      1/2 * size,    size*math.sqrt(3)/2,
      -1/2 * size,   size*math.sqrt(3)/2,
      -size,         0,
      -1/2 * size,   -size*math.sqrt(3)/2,
      1/2 * size,    -size*math.sqrt(3)/2
    }
  pad.init(size)
  self.touches = {}

  local special_pads = table.autotable(2)

  local id = 1
  for q, r in self:spiralIter(0, 0, self.radius) do
    local special_pad = special_pads[q][r]
    if special_pad then
      self.table[q][r] = pad[special_pad.constructor](id, q, r, unpack(special_pad.arguments))
    else
      self.table[q][r] = pad.new_tonepad(id, q, r)
    end
    id = id + 1
  end
  return self
end

-- QR from XYZ coordinates
local function cubeToAxial(x, y, z)
  return x, z
end

-- XYZ from QR coordinates
local function axialToCube(q, r)
  return q, -q-r, r
end

-- snap XYZ to nearest cell center XYZ
local function hexRounder(x, y, z)
  local rx = math.floor(x + 0.5)
  local ry = math.floor(y + 0.5)
  local rz = math.floor(z + 0.5)
  local x_diff = math.abs(rx - x)
  local y_diff = math.abs(ry - y)
  local z_diff = math.abs(rz - z)

  if x_diff > y_diff and x_diff > z_diff then
    rx = -ry - rz
  elseif y_diff > z_diff then
    ry = -rx - rz
  else
    rz = -rx - ry
  end
  return rx, ry, rz
end

local axial_directions = {
   { 1, -1}, { 0, -1}, {-1,  0}, {-1,  1}, { 0,  1}, { 1,  0}
}

-- get QR of cell in specified direction from QR cell
local function hexNeighbor(q, r, direction)
  local dir = axial_directions[direction]
  return q + dir[1], r + dir[2]
end

-- generate iterator that spirals from center QR cell until specified radius
function GridHex:spiralIter(q, r, radius)
  local q, r = q, r
  local rad = 0
  local ring = 0

  return function()
    if rad == 0 then
      rad = rad + 1
      ring = -1
      return q, r
    else
      if ring == -1 then -- move to bigger radius ring
        ring = 0
        if rad > 1 then
          q, r = hexNeighbor(q, r, 6)
        end
        if rad > radius then
          return nil
        end
        q, r = hexNeighbor(q, r, 5)
        return q, r
      else -- move to next tile on current ring
        local dir = 1 + math.floor(ring / rad)
        q, r = hexNeighbor(q, r, dir)
        ring = ring + 1
        if ring >= rad * 6 - 1 then
          rad = rad + 1
          ring = -1
        end
        return q, r
      end
    end
  end
end

-- 2D XY center of cell from QR coordinates
function GridHex:hexToPixel(q, r)
  local x = self.size * 3 / 2 * q
  local y = self.size * math.sqrt(3) * (r + q/2)
  return x, y
end

-- QR cell from 2D XY coordinate
function GridHex:pixelToHex(x, y)
  local q = x * 2/3 / self.size
  local r = (y * math.sqrt(3)/3 - x/3) / self.size
  return cubeToAxial(hexRounder(axialToCube(q, r)))
end

function GridHex:touchpressed(id, x, y, dx, dy, pressure)
  local q, r = self:pixelToHex(x, y)
  self.touches[id] = {q, r, x, y}
  self.table[q][r]:pressed(q, r)
end

function GridHex:touchmoved(id, x, y, dx, dy, pressure)
    local q, r = self:pixelToHex(x, y)

    if self.touches[id] then
      if q == self.touches[id][1] and r == self.touches[id][2] then
        self.table[q][r]:moved(dx, dy)
      else
        local qr, rr = unpack(self.touches[id])
        self.table[qr][rr]:released(qr, rr)
        self.table[q][r]:pressed(q, r)
      end
    end
    self.touches[id] = {q, r, x, y}
end

function GridHex:touchreleased(id, x, y, dx, dy, pressure)
  if self.touches[id] then
    local q, r = unpack(self.touches[id])
    self.table[q][r]:released(q, r)
  end
  self.touches[id] = nil
end

return GridHex
