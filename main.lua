local l = require('lume')

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
      log('a new patch is selected')
      patch.load()
    end
  end
end

function love.keypressed(key)
  if key == 'escape' then
    if patch then
      patch = nil
      log('patch unloaded')
    else
      love.event.quit()
    end
  end
end
