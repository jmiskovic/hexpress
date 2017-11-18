local l = require('lume')

local colorScheme = {
  background    = {0.28, 0.27, 0.35, 1.00},
  pad_highlight = {0.96, 0.49, 0.26, 1.00},
  pad_surface   = {0.21, 0.21, 0.27, 1.00},
  white         = {1.00, 1.00, 1.00, 1.00},
}


local controls = require('controls')
local selector = require('selector')

local time = 0
local sw, sh
local patch
local stream = {}

function love.resize()
  sw, sh = love.graphics.getDimensions()
end

function love.load()
  require('toolset') -- import module only after love.draw is defined
  love.resize() -- force layout re-configuration
  controls.load()
  selector.load('patches', sw, sh)
  love.graphics.setBackgroundColor(colorScheme.background)
end

function love.draw()
  if patch and patch.draw then
    patch.draw(stream)
  else
    selector.draw(time)
  end
end

function love.update(dt)
  time = time + dt

  if patch then
    stream = {   --spring
      dt = dt,
      time = time,
    }
    controls.process(stream)
    patch.process(stream)
  else
    patch = selector.selected()
    if patch then
      patch.load(colorScheme)
    end
  end
end

function love.keypressed(key)
  if key == 'escape' then
    if patch then
      patch = nil
      love.audio.stop()
    else
      love.event.quit()
    end
  end
end
