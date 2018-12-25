local l = require('lume')

local controls = require('controls')
local selector = require('selector')
local efx      = require('efx')
local mock     = require('mock')

local time = 0
local sw, sh, dpi
local patch = selector
local stream = {}

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
  mock.load()
  love.audio.setPosition(0, -1, 0)
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

  stream = {   --spring
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
  patch.process(stream)
  efx.process(stream)
  love.timer.sleep(0.003)
  --record(stream)
  -- falls
end

function record(s, tape)
  for _,touch in pairs(s.touches) do
    if touch.noteRetrigger then
      table.insert(tape, {s.time, touch.note})
      print(s.time, touch.note)
    end
  end
end

function play(s, tape, when)
  for _, e in ipairs(tape) do
    local time, note = e

    if time > when - s.dt and time < when then
      table.insert(s.touches)
    end
    if time > when then break end
  end
end

function love.draw()
  love.graphics.origin()
  transform()
  patch.draw(stream)
  love.graphics.origin()
  --mock.draw(stream)
  --drawTable(stream)
  --track('fps %2.1f', love.timer.getFPS())
end

function love.visible(visible)
  if not visible then
    love.event.quit()
  end
end

function loadPatch(newPatch)
  time = 0   -- back to big bang
  efx.load() -- restore efx to defaults
  patch = newPatch
  patch.load()
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
