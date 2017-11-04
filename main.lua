local hexgrid = require('hexgrid')
local synths = require('synths')
local controls = require('controls')
local presets = require('presets')

local preset_selection = presets[1]
local sw, sh
local hexgrid_center

function love.resize()
  sw, sh = love.graphics.getDimensions()
  hexgrid_center = {sw/2, sh/2}
  grid = hexgrid.new(sw / 13.5, 5)
end

function love.load()
  require('toolset') -- import module only after love.draw is defined
  love.resize() -- force layout re-configuration
  controls.load()
  love.focus()
end

function love.focus()
  synths.load(preset_selection)
end

function love.draw()
  grid:draw(hexgrid_center[1], hexgrid_center[2])
end

function love.update(dt)
  controls.update(dt)
  synths.update(dt)
end

local lastnote = 0

function love.touchpressed(id, x, y, dx, dy, pressure)
  grid:touchpressed(id, x - hexgrid_center[1], y - hexgrid_center[2], dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  grid:touchmoved(id, x - hexgrid_center[1], y - hexgrid_center[2], dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  grid:touchreleased(id, x, y, dx, dy, pressure)
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  elseif key == 'menu' or key == 'tab' then
    local index = 0
    for k,v in ipairs(presets) do
      if preset_selection == v then
        index = k
        break
      end
    end
    index = (index % #presets) + 1
    preset_selection = presets[index]
    synths.load(preset_selection)
  end
end
