local l = require('lume')

local controls = require('controls')
local interpreting = require('interpreting')


local honeycomb = require('honeycomb')

local pipeline = {
  controls,
  interpreting,
  require('patches/strings'),
}

local time = 0

local sw, sh = love.graphics.getDimensions()
local grid

local splash = love.graphics.newImage('splash.png')
local stream = {}

function love.resize()
  sw, sh = love.graphics.getDimensions()
  grid = honeycomb.new(sw / 2, sh / 2, sh / 7.8, 6, 4)
end

local selector = require('selector')

function love.load()
  selector.place(sw/2, sh/2)
  require('toolset') -- import module only after love.draw is defined
  love.resize() -- force layout re-configuration
  local settings = {}
  for _, element in ipairs(pipeline) do
    element.load(settings)
  end
  selector.load('patches')
end

function love.draw()
  selector.draw()
--  grid:draw()
--  drawTable(stream)
--  love.graphics.setColor(1, 1, 1, l.remap(time, 2.5, 2, 0, 1, 'clamp'))
--  love.graphics.translate(sw/2, sh/2)
--  love.graphics.draw(splash, -splash:getWidth() / 2, -splash:getHeight() / 2)
--  love.graphics.origin()
end


function love.update(dt)
  selector.update(dt)
  time = time + dt

  stream = {   --spring
    dt = dt,
    time = time,
  }

  for _, element in ipairs(pipeline) do
    stream = element.process(stream)
  end
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  end
end
