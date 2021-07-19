local hexgrid = {}

hexgrid.__index = hexgrid

-- vertices for tile shape that spans from -1 to 1 (has to be scaled to needed size)
hexgrid.hexagon = { 1,  0, 1/2, math.sqrt(3)/2, -1/2, math.sqrt(3)/2, -1,  0, -1/2, -math.sqrt(3)/2, 1/2, -math.sqrt(3)/2 }
hexgrid.roundhex = {1.000,0.065,0.984,0.143,0.940,0.254,0.876,0.388,0.798,0.530,0.714,0.668,0.630,0.791,0.556,0.885,0.496,0.938,0.421,0.963,0.302,0.981,0.154,0.991,-0.008,0.995,-0.170,0.991,-0.318,0.981,-0.437,0.963,-0.512,0.938,-0.572,0.885,-0.646,0.791,-0.729,0.668,-0.814,0.530,-0.892,0.388,-0.956,0.254,-1.000,0.143,-1.017,0.065,-1.000,-0.013,-0.956,-0.125,-0.892,-0.258,-0.814,-0.400,-0.729,-0.539,-0.646,-0.662,-0.572,-0.756,-0.512,-0.809,-0.437,-0.834,-0.318,-0.851,-0.170,-0.862,-0.008,-0.866,0.154,-0.862,0.302,-0.851,0.421,-0.834,0.496,-0.809,0.556,-0.756,0.630,-0.662,0.714,-0.539,0.798,-0.400,0.876,-0.258,0.940,-0.125,0.984,-0.013}


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
   { 0, -1}, {-1,  0}, {-1,  1}, { 0,  1}, { 1,  0}, { 1, -1}
}

-- get QR of cell in specified direction from QR cell, directions coding:
--     1
--  2     6
--
--  3     5
--     4
-- (direction 1 is N, 2 is NW, 3 is SW...)
local function hexNeighbor(q, r, direction)
  local dir = axial_directions[direction]
  return q + dir[1], r + dir[2]
end

-- generate iterator that spirals from center QR cell until specified radius
function hexgrid.spiralIter(q, r, radius)
  local rad = 0
  local ring = 0 -- iterator over ring, when completed set to -1

  return function()
    if rad == 0 then    -- center hex
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

-- QR from XYZ coordinates
function hexgrid.cubeToAxial(x, y, z)
  return x, z
end

-- XYZ from QR coordinates
function hexgrid.axialToCube(q, r)
  return q, -q-r, r
end

-- 2D XY center of cell from QR coordinates
function hexgrid.hexToPixel(q, r)
  local x = 3 / 2 * q
  local y = math.sqrt(3) * (r + q/2)
  return x, y
end

-- QR cell from 2D XY coordinate
function hexgrid.pixelToHex(x, y)
  x = x
  y = y
  local q = x * 2/3
  local r = y * math.sqrt(3)/3 - x/3
  return hexgrid.cubeToAxial(hexRounder(hexgrid.axialToCube(q, r)))
end

function hexgrid.distanceFromCenter(q, r)
  local a, b, c = hexgrid.axialToCube(q, r)
  return (math.abs(a) + math.abs(b) + math.abs(c))/2
end

return hexgrid
