local mock = {}

local l = require('lume')

local font
local fontSize = 16
local mockTilt

function mock.load()
  font = love.graphics.newFont("Ubuntu-B.ttf", fontSize)
  mockTilt = {0, 0, 0}
end

function mock.process(s)
  if not s.tilt then return end
  local mx, my = love.mouse.getPosition()
  if love.keyboard.isDown('lshift') then
    mockTilt[1] = l.remap(mx, 0, s.sw, -1, 1)
    mockTilt[2] = l.remap(my, 0, s.sh, -1, 1)
  elseif love.keyboard.isDown('lctrl') then
    mockTilt[3] = l.remap(my, 0, s.sh, 1, - 1)
  end
  s.tilt = {
    mockTilt[1],
    mockTilt[2],
    mockTilt[3],
    lp = {
      mockTilt[1],
      mockTilt[2],
      mockTilt[3],
    },
  }
  return s
end

function mock.draw(s)
-- tilt sensor visualization
  local barsize = 40
  love.graphics.setFont(font)
  -- vertical bar for tilt[2] (pitch)
  if not s.sw and not s.sh then return end
  love.graphics.translate(s.sw - 2 * barsize, s.sh / 2)
  love.graphics.scale(0.7)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', 0, -s.sh / 2, barsize, s.sh)
  love.graphics.setColor(1, 1, 0, 0.5)
  love.graphics.rectangle('fill', 0, 0, barsize, -s.sh / 2 * s.tilt[2])
  love.graphics.print(s.tilt[2], barsize * 1.1, -s.sh / 2 * s.tilt[2])
  love.graphics.origin()
  -- horizontal bar for tilt[1] (yaw)
  love.graphics.translate(s.sw / 2, s.sh - 2 * barsize)
  love.graphics.scale(0.7)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', -s.sw / 2, 0, s.sw, barsize)
  love.graphics.setColor(1, 1, 0, 0.5)
  love.graphics.rectangle('fill', 0, 0, s.sw / 2 * s.tilt[1], barsize)
  love.graphics.print(s.tilt[1], s.sw / 2 * s.tilt[1], barsize * 1.1)
  love.graphics.origin()
  -- scaling square for tilt[3] (roll)
  local barsize = 80
  love.graphics.translate(s.sw - 2 * barsize, s.sh - 2 * barsize)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', -barsize / 2, -barsize / 2, barsize, barsize)
  love.graphics.setColor(1, 1, 0, 0.5)
  barsize = l.remap(s.tilt[3], -1, 1, 0, barsize)
  love.graphics.rectangle('fill', -barsize / 2, -barsize / 2, barsize, barsize)
  love.graphics.print(s.tilt[3], 0, 0)
  love.graphics.origin()
end

return mock