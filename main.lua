local l = require('lume')

local controls = require('controls')
local selector = require('selector')
local efx      = require('efx')
local mock     = require('mock')

local time = 0
local sw, sh
local patch = selector
local stream = {}

function love.resize()
  sw, sh = love.graphics.getDimensions()
  require('toolset') -- import module only after love.draw is defined
  controls.load()
  selector.load('patches', sw, sh)
end

function love.load()
  efx.load()
  love.resize() -- force layout re-configuration
  mock.load()
  love.audio.setPosition(0, -2, 0)
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

  patch.process(stream)
  efx.process(stream)
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

function loadPatch(newPatch)
  patch = newPatch
  patch.load()
end

function love.keypressed(key)
  if key == 'escape' then
    if patch == selector then
      love.event.quit()
    else
      patch = selector
      love.audio.stop()
    end
  end
end