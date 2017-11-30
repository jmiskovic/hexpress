local l = require('lume')

local controls = require('controls')
local selector = require('selector')
local efx      = require('efx')
local mock     = require('mock')

local hotswapped = {  -- list of modules that require dynamic re-loading
  'controls',
  'efx',
  'sampler',
  'mock',
}

local time = 0
local sw, sh, dpi
local patch = selector
local stream = {}

function love.resize()
  sw, sh = love.graphics.getDimensions()
  dpi = love.window.getDPIScale()
  require('toolset') -- import module only after love.draw is defined
  controls.load()
  selector.load('patches', sw, sh)
end

function love.load()
  efx.load()
  love.resize() -- force layout re-configuration
  mock.load()
  love.audio.setPosition(0, -2, 0)
  love.graphics.translate(sw / 2, sh / 2)
end

function transform()
  -- use same set of transformations in both draw() and update() functions
  -- it's extracted here because if they deverge, it takes time to detect and debug

  -- set (0,0) to screen center and 1 unit to half-screen hight
  love.graphics.translate(sw / 2, sh / 2)
  love.graphics.scale(sh / 2, sh / 2)
end

function love.update(dt)
  love.graphics.origin()
  transform()
  time = time + dt

  stream = {   --spring
    dt = dt,
    time = time,
    width = sw,
    height = sh,
    dpi = dpi,
    -- todo: dpi, after investigating what's happening with love.window.getPixelScale()
  }

  controls.process(stream)

  if love.system.getOS() ~= 'Android' then
    mock.process(stream)
  end

  patch.process(stream)
  efx.process(stream)
end

function love.draw()
  love.graphics.origin()
  transform()
  patch.draw(stream)
  love.graphics.origin()
  --mock.draw(stream)
  --drawTable(stream)
  track('fps %2.1f', love.timer.getFPS())
end

function loadPatch(newPatch)
  patch = newPatch
  for _, name in ipairs(hotswapped) do
    local m, err  = l.hotswap(name)
    if m then
      if m.load then m.load() end
    else
      -- TODO
    end
  end
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
