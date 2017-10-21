local hexgrid = require('hexgrid')
local synths = require('synths')
local controls = require('controls')
local presets = require('presets')

require ('log')

local sw, sh = love.graphics.getDimensions()
local hexgrid_center = {sw/2, sh/2}

local grid = hexgrid.new(sw / 12.42, 5)
local preset_selection = presets.organ

function love.load()
  controls.load()
  love.focus()
end

function love.focus()
  synths.load(preset_selection)
end

function love.resize()
  sw, sh = love.graphics.getDimensions()
  hexgrid_center = {sw/2, sh/2}
  grid = hexgrid.new(sw / 12.42, 5)
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
    if preset_selection == presets.organ then
      preset_selection = presets.rhodes
    else
      preset_selection = presets.organ
    end
    synths.load(preset_selection)
  end
end
