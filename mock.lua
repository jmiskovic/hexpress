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
    mockTilt[1] = l.remap(mx, 0, s.width, -1, 1)
    mockTilt[2] = l.remap(my, 0, s.height, -1, 1)
  end
  if love.keyboard.isDown('lctrl') then
    mockTilt[3] = l.remap(my, 0, s.height, 1, - 1)
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

  if love.keyboard.isDown('r') then -- soundbyte record
    s.touches[1] = {818, 73, velocity = 0.1}
  end
  if love.keyboard.isDown('w') then -- tape record
    s.touches[1] = {64, 64, velocity = 0.1}
  end
  if love.keyboard.isDown('a') then
    s.touches[1] = {250, 250, velocity = 0.1}
  end
  if love.keyboard.isDown('s') then
    s.touches[1] = {250, 250, velocity = 0.9}
  end
  if love.keyboard.isDown('d') then
    s.touches[1] = {250, 550, velocity = 0.9}
  end
  if love.keyboard.isDown('q') then
    s.touches[1] = {196, 106, velocity = 0.9}
  end
  if love.keyboard.isDown('f1') then
    local sampler = require('sampler')
    sampler.logSamples = true
  end
  return s
end

function mock.draw(s)
-- tilt sensor visualization
  local barsize = 40
  love.graphics.setFont(font)
  -- vertical bar for tilt[2] (pitch)
  if not s.width and not s.height then return end
  love.graphics.push()
  love.graphics.translate(s.width - 2 * barsize, s.height / 2)
  love.graphics.scale(0.7)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', 0, -s.height / 2, barsize, s.height)
  love.graphics.setColor(1, 1, 0, 0.5)
  love.graphics.rectangle('fill', 0, 0, barsize, -s.height / 2 * s.tilt[2])
  love.graphics.print(s.tilt[2], barsize * 1.1, -s.height / 2 * s.tilt[2])
  love.graphics.pop()
  -- horizontal bar for tilt[1] (yaw)
  love.graphics.push()
  love.graphics.translate(s.width / 2, s.height - 2 * barsize)
  love.graphics.scale(0.7)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', -s.width / 2, 0, s.width, barsize)
  love.graphics.setColor(1, 1, 0, 0.5)
  love.graphics.rectangle('fill', 0, 0, s.width / 2 * s.tilt[1], barsize)
  love.graphics.print(s.tilt[1], s.width / 2 * s.tilt[1], barsize * 1.1)
  love.graphics.pop()
  -- scaling square for tilt[3] (roll)
  barsize = 80
  love.graphics.push()
  love.graphics.translate(s.width - 2 * barsize, s.height - 2 * barsize)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', -barsize / 2, -barsize / 2, barsize, barsize)
  love.graphics.setColor(1, 1, 0, 0.5)
  barsize = l.remap(s.tilt[3], -1, 1, 0, barsize)
  love.graphics.rectangle('fill', -barsize / 2, -barsize / 2, barsize, barsize)
  love.graphics.print(s.tilt[3], 0, 0)
  love.graphics.print(math.acos(s.tilt[3])/math.pi*180, 0, 15)
  love.graphics.print(math.atan(s.tilt[2], s.tilt[3])/math.pi*180, 0, 30)
  love.graphics.print(math.atan(-s.tilt[1], math.sqrt(s.tilt[3]^2 + s.tilt[2]^2))/math.pi*180, 0, 45)
  love.graphics.pop()
end

return mock
