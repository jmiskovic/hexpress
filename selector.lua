local l = require('lume')

local selector = {}
local splashImage


require('autotable')
local hexgrid = require('hexgrid')
local faultyPatch = require('faultyPatch')

local radius = 0    -- inflated to actual size while loading patches
local scale = 100
local gap = 30
local cx, cy = 0, 0

local patches = table.autotable(2)

function selector.load(path, sw, sh)
  splashImage = love.graphics.newImage('splash.png')
  local i = 1
  local fileList = love.filesystem.getDirectoryItems(path)
  for q, r in hexgrid.spiralIter(0, 0, math.huge) do
    if i > #fileList then
      break
    end
    local loadPath = path .. '/' .. fileList[i]

    local ok, chunk, result
    ok, chunk = pcall(love.filesystem.load, loadPath) -- load the chunk safely
    if ok then
      ok, result = pcall(chunk) -- execute the chunk safely
    end
    if ok  then
      patches[q][r] = result
    else
      log(chunk)
      patches[q][r] = faultyPatch.new(result)
    end

    radius = hexgrid.distanceFromCenter(q, r)
    i = i+1
  end
  scale = sh / radius / 8
  gap = scale * 0.3
  cx, cy = sw/2, sh/2
end

function selector.selected()
  selected = nil  -- default return value for when nothing's selected yet
  for _,id in ipairs(love.touch.getTouches()) do
    local x, y = love.touch.getPosition(id)
    local q, r = hexgrid.pixelToHex(x, y, cx, cy, scale + gap)

    if hexgrid.distanceFromCenter(q,r) < radius + 1 then
      selected = patches[q][r]
      break
    end
  end
  return selected
end

function selector.draw(time)
  for q, t in pairs(patches) do
    for r, patch in pairs(t) do
      local x, y = hexgrid.hexToPixel(q, r, cx, cy, scale + gap)
      love.graphics.translate(x, y)
      love.graphics.scale(scale)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.stencil(stencilFunc, "replace", 1)
      love.graphics.setStencilTest("greater", 0)
      local ok, err = pcall(patch.icon, time)
      if not ok then
        selector.defaultIcon(q, r)
        log(err)
      end
      love.graphics.setStencilTest()
      love.graphics.setLineWidth(0.2)
      love.graphics.setColor(1,1,1,0.3)
      love.graphics.circle('line', 0, 0, 1)
      love.graphics.origin()
    end
  end
  -- draw the splashscreen with fade out
  local splashToScreenRatio = 0.6
  local scale = cx * 2 / splashImage:getWidth() * splashToScreenRatio
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(splashImage, cx/2, 0, 0, scale, scale)

end

function selector.defaultIcon(q, r)
  local name = patches[q][r].name
  if name then -- quick & dirty way to have unique color per patch name
    local hash = 0
    for i=1,#name do
      hash = hash + string.byte(name, i) * (i % 5 + 1)
    end
    love.math.setRandomSeed(hash)
  else
    love.math.setRandomSeed(q * 17 + r * 43)
  end
  love.graphics.setColor(love.math.random(), love.math.random(), love.math.random())
  love.graphics.rectangle('fill', -1, -1, 2, 2)
end

function stencilFunc()
  love.graphics.circle('fill', 0, 0, 1)
end

return selector
