local l = require('lume')

local controls = require('controls')
local selector = require('selector')
local recorder = require('tapeRecorder')
local efx      = require('efx')
local mock     = require('mock')

local time = 0
local sw, sh, dpi
local patch = selector
local stream = {}
local tape1, tape2

function love.resize()
  sw, sh = love.graphics.getDimensions()
  dpi = love.window.getDPIScale()
end


function love.load()
  efx.load()
  love.resize() -- force layout re-configuration
  require('toolset') -- import module only after love.draw is defined
  controls.load()
  selector.load('patches')
  tape1 = recorder.create()
  tape1.position = {-1.65, -0.88}
  tape2 = recorder.create()
  tape2.position = {-1.30, -0.88}
  mock.load()
  love.audio.setPosition(0, 0, 0)
  love.audio.setVolume(1)
  love.graphics.translate(sw / 2, sh / 2)
end


function transform()
  -- use same set of transformations in both draw() and update() functions
  -- it's extracted here because if they diverge, it takes time to detect and debug
  -- set (0,0) to screen center and 1 unit to half-screen hight
  love.graphics.translate(sw / 2, sh / 2)
  love.graphics.scale(sh / 2, sh / 2)
end


function love.update(dt)
  love.graphics.origin()
  transform()
  time = time + dt
  --stream is created
  stream = {
    dt = dt,
    time = time,
    width = sw,
    height = sh,
    dpi = dpi,
  }

  controls.process(stream)
  if love.system.getOS() ~= 'Android' then
    mock.process(stream)
  end
  patch:process(stream)
  local t2r = tape2.recording
  tape1:process(stream, patch)
  tape2:process(stream, patch)
  if t2r and not tape2.recording then
    tape2.time = 0
    tape2.time = tape2.length - tape1.length -- align start
    tape2.length = tape1.length
  end
  efx.process(stream)
  love.timer.sleep(0.003)
  --stream is garbage collected
end


function love.draw()
  love.graphics.origin()
  transform()
  patch:draw(stream)
  tape1:draw()
  tape2:draw()
  love.graphics.origin()
  --mock.draw(stream)
  --drawTable(stream)
  track("t %1.1f %1.1f", {tape1.time, tape2.time})
  --track('fps %2.1f', love.timer.getFPS())
end


function loadPatch(newPatch)
  time = 0   -- back to big bang
  efx.load() -- restore efx to defaults
  patch = newPatch.load()
  tape1:patchChanged(newPatch)
  tape2:patchChanged(newPatch)
end


function love.keypressed(key)
  if key == 'escape' then
    if patch == selector then
      love.event.quit()
    else
      loadPatch(selector)
      love.audio.stop()
    end
  elseif key == 'menu' or key == 'f' then
    controls.frozen = not controls.frozen
  end


end
