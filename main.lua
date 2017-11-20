local l = require('lume')

local controls = require('controls')
local selector = require('selector')
local efx      = require('efx')

local time = 0
local sw, sh
local patch
local stream = {}

function love.resize()
  sw, sh = love.graphics.getDimensions()
  require('toolset') -- import module only after love.draw is defined
  controls.load()
  selector.load('patches', sw, sh)
  efx.load()
end

function love.load()
  love.resize() -- force layout re-configuration
  log('screen', sw, sh)
  log('desktop', love.window.getDesktopDimensions())
end

function love.draw()
  if patch and patch.icon then
    love.graphics.translate(sw / 2, sh / 2)
    love.graphics.scale(sw/2)
    patch.icon(time)
    love.graphics.origin()
  end
  if patch and patch.draw then
    patch.draw(stream)
  else
    selector.draw(time)
  end
  --drawTable(stream)
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
      patch.load()
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
