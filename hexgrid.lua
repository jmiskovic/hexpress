local hexgrid = {}

hexgrid.__index = hexgrid

-- vertices for tile shape that spans from -1 to 1 (has to be scaled to needed size)
hexgrid.shape = { 1,  0, 1/2, math.sqrt(3)/2, -1/2, math.sqrt(3)/2, -1,  0, -1/2, -math.sqrt(3)/2, 1/2, -math.sqrt(3)/2 }

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
-- direction 1 is NE, 2 is N, 3 is NW...
local function hexNeighbor(q, r, direction)
  local dir = axial_directions[direction]
  return q + dir[1], r + dir[2]
end

-- generate iterator that spirals from center QR cell until specified radius
function hexgrid.spiralIter(q, r, radius)
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
function hexgrid.hexToPixel(q, r, cx, cy, size)
  local x = size * 3 / 2 * q + cx
  local y = size * math.sqrt(3) * (r + q/2) + cy
  return x, y
end

-- QR cell from 2D XY coordinate
function hexgrid.pixelToHex(x, y, cx, cy, size)
  x = x - cx
  y = y - cy
  local q = x * 2/3 / size
  local r = (y * math.sqrt(3)/3 - x/3) / size
  return cubeToAxial(hexRounder(axialToCube(q, r)))
end

return hexgrid
