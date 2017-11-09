local GridHex = require('GridHex')
local synths = require('synths')
local controls = require('controls')
local presets = require('presets')

time = 0
instrumentSelect = false
presetIndex = 1
local preset_selection = presets[presetIndex]
local sw, sh
local hexgrid_center
local backInterval = 0.5
local lastBackTime = -10
local startAppTime = love.timer.getTime()

function love.resize()
  sw, sh = love.graphics.getDimensions()
  hexgrid_center = {sw/2, sh/2}
  grid = GridHex.new(sh / 7.8, 6)
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

local headphones = love.graphics.newImage('headphones.png')

-- iterate through and draw pad grid
function drawGrid(cx, cy)
  for q, r in grid:spiralIter(0, 0, 6) do
    if grid.table[q][r] then
      local x, y = grid:hexToPixel(q, r)
      grid.table[q][r]:draw(x + cx, y + cy)
    end
  end
end

function love.draw()
  drawGrid(hexgrid_center[1], hexgrid_center[2])
  if time - lastBackTime < backInterval then
    exitText = 'Press again to exit'
    local font = love.graphics.getFont()
    local x = sw / 2 - font:getWidth(exitText) / 2
    local y = sh - font:getHeight() * 4
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(exitText, x, y)
  end
  love.graphics.setColor(1, 1, 1, 0.8 - time + 2)
  love.graphics.translate(sw/2, sh/2)
  love.graphics.scale(0.6 * sh / headphones:getHeight())
  love.graphics.draw(headphones, -headphones:getWidth() / 2, -headphones:getHeight() / 2)
  love.graphics.origin()
end

function love.update(dt)
  time = love.timer.getTime() - startAppTime
  controls.update(dt)
  synths.update(dt)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  if instrumentSelect == true then
    instrumentSelect = false
    local q, r = grid:pixel_to_hex(x - hexgrid_center[1], y - hexgrid_center[2])
    presetIndex = ((grid.table[q][r].id - 1) % #presets) + 1
    preset_selection = presets[presetIndex]
    synths.load(preset_selection)
    love.math.setRandomSeed(grid.table[q][r].id)
    local background    = {0.28, 0.27, 0.35}
    local color = {love.math.random(), love.math.random(), love.math.random()}
    for i,v in ipairs(color) do
      color[i] = background[i] * 0.95 + color[i] * 0.05
    end
    love.graphics.setBackgroundColor(color)
  end
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
    instrumentSelect = true
    local backTime = time
    if backTime - lastBackTime < backInterval then
      love.event.quit()
    end
    lastBackTime = backTime
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
