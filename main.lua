local l = require('lume')

local honeycomb = require('honeycomb')
local synths = require('synths')
local controls = require('controls')
local patches = require('patches')

time = 0  -- yes, time is global

local sw, sh = love.graphics.getDimensions()
local grid
local currentPatch = patches[1]
local startAppTime = love.timer.getTime()
local doubleBackInterval = 0.5
local lastBackTime = -10

local splash = love.graphics.newImage('splash.png')

function love.resize()
  sw, sh = love.graphics.getDimensions()
  grid = honeycomb.new(sw / 2, sh / 2, sh / 7.8, 6, 4)
end

function love.load()
  require('toolset') -- import module only after love.draw is defined
  love.resize() -- force layout re-configuration
  controls.load()
  love.focus()
end

function love.focus()
  synths.load(currentPatch)
end

-- iterate through and draw pad grid

function love.draw()
  grid:draw()
  if time - lastBackTime < doubleBackInterval then
    exitText = 'Press again to exit'
    local font = love.graphics.getFont()
    local x = sw / 2 - font:getWidth(exitText) / 2
    local y = sh - font:getHeight() * 4
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(exitText, x, y)
  end
  love.graphics.setColor(1, 1, 1, l.remap(time, 2.5, 2, 0, 1, 'clamp'))
  love.graphics.translate(sw/2, sh/2)
  love.graphics.draw(splash, -splash:getWidth() / 2, -splash:getHeight() / 2)
  love.graphics.origin()
end

function love.update(dt)
  time = love.timer.getTime() - startAppTime
  controls.update(dt)
  synths.update(dt)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  grid:touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  grid:touchmoved(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  grid:touchreleased(id, x, y, dx, dy, pressure)
end

function love.keypressed(key)
  if key == 'escape' then
    local backTime = time
    if backTime - lastBackTime < doubleBackInterval then
      love.event.quit()
    end
    lastBackTime = backTime
  end
end
