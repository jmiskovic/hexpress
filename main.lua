local hexgrid = require('hexgrid')
local synths = require('synths')


local sw, sh = love.graphics.getDimensions()
local hexgrid_center = {sw/2, sh/2}

local grid = hexgrid.new(sw / 12.42, 5)

function love.load()
  synths.load()
end

function love.resize()
  sw, sh = love.graphics.getDimensions()
  hexgrid_center = {sw/2, sh/2}
  grid = hexgrid.new(sw / 12.42, 7)
end

function love.draw()
  grid:draw(hexgrid_center[1], hexgrid_center[2])

  --local x, y = love.mouse.getPosition()
  --local q,r = grid:pixel_to_hex(x - hexgrid_center[1], y - hexgrid_center[2])
  --love.graphics.print(q..','..r, 0,0)
end

function love.update(dt)
  synths.update(dt)
end

local lastnote = 0

function love.touchpressed(id, x, y, dx, dy, pressure)
  grid:touchpressed(id, x - hexgrid_center[1], y - hexgrid_center[2], dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  grid:touchmoved(id, x - hexgrid_center[1], y - hexgrid_center[2], dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  grid:touchreleased(id, x, y, dx, dy, pressure)
end

function love.keypressed(key)
  if key == 'escape' then
      love.event.quit()
  end
end

