local l = require('lume')

local controls = require('controls')
local selector = require('selector')
local efx      = require('efx')
local mock     = require('mock')

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
  mock.load()
--  log('screen', sw, sh)
--  log('desktop', love.window.getDesktopDimensions())
end

function love.update(dt)
  time = time + dt

  stream = {   --spring
    dt = dt,
    time = time,
    sw = sw,
    sh = sh,
  }
  controls.process(stream)

  if love.system.getOS() ~= 'Android' then
    mock.process(stream)
  end

  if patch then
    patch.process(stream)
  else
    patch = selector.process(stream)
    if patch then
      patch.load()
    end
  end
end

function love.draw()
  if patch and patch.draw then
    patch.draw(stream)
  else
    selector.draw(stream)
  end
  mock.draw(stream)
  --drawTable(stream)
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
