local l = require('lume')

local controls = require('controls')

local time = 0

local sw, sh = love.graphics.getDimensions()
local grid

local splash = love.graphics.newImage('splash.png')
local stream = {}

function love.resize()
  sw, sh = love.graphics.getDimensions()
end

local selector = require('selector')

function love.load()
  require('toolset') -- import module only after love.draw is defined
  love.resize() -- force layout re-configuration
  controls.load()

  selector.load('patches', sw, sh)
end

function love.draw()
  selector.draw(time)
--  grid:draw()

  -- draw and fade out splashscreen
  local splashToScreenRatio = 0.6
  local fadeOutAfter = 2.0
  local fadeOutTime  = 0.5
  if time < fadeOutAfter then
    love.graphics.setColor(1, 1, 1, l.remap(time, fadeOutAfter + fadeOutTime, fadeOutAfter, 0, 1, 'clamp'))
    love.graphics.translate(sw/2, sh/2)
    love.graphics.scale(sw/splash:getWidth() * splashToScreenRatio)
    love.graphics.draw(splash, -splash:getWidth() / 2, -splash:getHeight() / 2)
    love.graphics.origin()
  end
end


function love.update(dt)
  selector.update(dt)
  time = time + dt

  stream = {   --spring
    dt = dt,
    time = time,
  }

  controls.process(stream)
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end
