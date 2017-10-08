local hexgrid = {}

hexgrid.__index = hexgrid

local cube_directions = {
   { 1, -1,  0}, { 1,  0, -1}, { 0,  1, -1},
   {-1,  1,  0}, {-1,  0,  1}, { 0, -1,  1}
}

local axial_directions = {
   { 1, -1}, { 0, -1}, {-1,  0}, {-1,  1}, { 0,  1}, { 1,  0}
}


-- get QR of cell in specified direction from QR cell
local function hex_neighbor(q, r, direction)
  local dir = axial_directions[direction]
  return q + dir[1], r + dir[2]
end

-- specify new grid with cell size and grid span ('radius' from center cell)
function hexgrid.new(size, radius)
  local self = setmetatable({}, hexgrid)
  self.note_offset = 4
  self.size = size or 10
  self.radius = radius or 5
  size = size * 0.95
  self.hexapoly = {
      size,          0,
      1/2 * size,    size*math.sqrt(3)/2,
      -1/2 * size,   size*math.sqrt(3)/2,
      -size,         0,
      -1/2 * size,   -size*math.sqrt(3)/2,
      1/2 * size,    -size*math.sqrt(3)/2
    }
  self.touches = {}
  self.font = love.graphics.newFont("Ubuntu-B.ttf", size)
  self.font_color = {0.13, 0.13, 0.13, 0.5}
  return self
end

-- QR from XYZ coordinates
local function cube_to_axial(x, y, z)
  return x, z
end

-- XYZ from QR coordinates
local function axial_to_cube(q, r)
  return q, -q-r, r
end

-- snap XYZ to nearest cell center XYZ
local function hex_rounder(x, y, z)
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

-- generate iterator that spirals from center QR cell until specified radius
function spiral_iter(q, r, radius)
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
          q, r = hex_neighbor(q, r, 6)
        end
        if rad > radius then
          return nil
        end
        q, r = hex_neighbor(q, r, 5)
        return q, r
      else -- move to next tile on current ring
        local dir = 1 + math.floor(ring / rad)
        q, r = hex_neighbor(q, r, dir)
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
function hexgrid:hex_to_pixel(q, r)
  local x = self.size * 3 / 2 * q
  local y = self.size * math.sqrt(3) * (r + q/2)
  return x, y
end

-- QR cell from 2D XY coordinate
function hexgrid:pixel_to_hex(x, y)
  local q = x * 2/3 / self.size
  local r = (y * math.sqrt(3)/3 - x/3) / self.size
  return cube_to_axial(hex_rounder(axial_to_cube(q, r)))
end

function hexgrid:touchpressed(id, x, y, dx, dy, pressure)
  local q, r = grid:pixel_to_hex(x, y)
  self.touches[id] = {q, r, x, y}
  self:cellpressed(q, r)
end

function hexgrid:touchmoved(id, x, y, dx, dy, pressure)
    local q, r = grid:pixel_to_hex(x, y)

    if self.touches[id] then
      if q == self.touches[id][1] and r == self.touches[id][2] then
      else
        self:cellreleased(self.touches[id][1], self.touches[id][2])
        self:cellpressed(q, r)
      end
    end
    self.touches[id] = {q, r, x, y}
end

function hexgrid:touchreleased(id, x, y, dx, dy, pressure)
  if self.touches[id] then
    self:cellreleased(self.touches[id][1], self.touches[id][2])
  end
  self.touches[id] = nil
end

-- stub for callback
function hexgrid:cellpressed(q, r)
end

-- stub for callback
function hexgrid:cellreleased(q, r)
end

-- RENDERING

function hexgrid:draw_tonepad(q, r, cx, cy)
  local x, y = self:hex_to_pixel(q, r)
  local note_name = note_names[(self:hex_to_note(q, r)) % 12 +1]
  local gray = 0.43 - string.len(note_name) * 0.16
  love.graphics.setColor(gray + 0.1, gray + 0.2, gray)
  love.graphics.translate(cx + x, cy + y)
  love.graphics.polygon('fill', self.hexapoly)
  love.graphics.setColor(self.font_color)
  love.graphics.print(note_name, -self.font:getWidth(note_name)/2, -self.font:getHeight()/2)
  love.graphics.origin()
end

local grille_image = love.graphics.newImage('grille.png')

function hexgrid:draw_grille(q, r, cx, cy)
  local x, y = self:hex_to_pixel(q, r)
  x, y = x + cx, y + cy
  love.graphics.translate(x, y)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.stencil(
    function ()
      love.graphics.polygon('fill', self.hexapoly)
    end, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  local w, h = grille_image:getDimensions()
  love.graphics.draw(grille_image, - w/2, - h/2)
  love.graphics.setStencilTest()
  love.graphics.origin()
end

-- draw QR cell with XY offset
function hexgrid:draw_highlight(q, r, cx, cy)
  local x, y = self:hex_to_pixel(q,r)
  x, y = x + cx, y + cy
  love.graphics.setColor(1, 1, 1, 0.1)
  --love.graphics.print(q..','..r, 0, 0)
  love.graphics.translate(x, y)
  love.graphics.polygon('fill', self.hexapoly)
  love.graphics.origin()
end

local rendering_methods = {
 ['-4,0'] = hexgrid.draw_grille,
 ['-4,4'] = hexgrid.draw_grille,
 ['4,-4'] = hexgrid.draw_grille,
 ['4,0']  = hexgrid.draw_grille
}

-- iterate through and draw hex grid
function hexgrid:draw(cx, cy)
  love.graphics.setFont(self.font)
  for q, r in spiral_iter(0, 0, self.radius) do
    local render_func = rendering_methods[q..','..r] or self.draw_tonepad
    render_func(self, q, r, cx, cy)
  end
end

-- MUSICAL STUFF (TODO: extract from hexgrid)

note_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}

-- harmonic note grid from QR coordinate
function hexgrid:hex_to_note(q, r)
    return 24+q*4 + (-q-r)*7 + self.note_offset
end

return hexgrid
