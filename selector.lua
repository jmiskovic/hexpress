local l = require('lume')

local selector = {}

local colorScheme = {
  background = {l.rgba(0x2d2734ff)},
  frame      = {l.rgba(0xffffff22)}
}

require('autotable')
local hexgrid = require('hexgrid')
local faultyPatch = require('faultyPatch')
local radius = 0     -- inflated to actual size while loading patches
local scale = 1 / 2.7  -- fit about this many icons along vertical

local patches = {}

function selector.load()
  love.graphics.setBackgroundColor(colorScheme.background)
  patches = table.autotable(2)
  local i = 1
  -- try to load all patches in directory, store them in hexagonal spiral
  local fileList = love.filesystem.getDirectoryItems('patches')
  for q, r in hexgrid.spiralIter(0, 0, math.huge) do
    if i > #fileList then
      break
    end
    local iterName = fileList[i]
    local loadPath = 'patches/' .. iterName .. '/' .. iterName
    local m, err = l.hotswap(loadPath)
    if m then
      patches[q][r] = m
    else
      log(err)
      patches[q][r] = faultyPatch.new(err)
    end

    radius = hexgrid.distanceFromCenter(q, r)
    i = i+1
  end
  scale = 1 / (2 * radius + 0.7)
end

function selector.process(s)
  for _,id in ipairs(love.touch.getTouches()) do
    local x, y = love.touch.getPosition(id)
    love.graphics.scale(scale)
    x, y = love.graphics.inverseTransformPoint(x, y)
    local q, r = hexgrid.pixelToHex(x, y)

    if hexgrid.distanceFromCenter(q,r) < radius + 1 then
      local selected = patches[q][r]
      if selected then
        loadPatch(selected)
        break
      end
    end
  end
end

function selector.draw(s)
  for q, t in pairs(patches) do
    for r, patch in pairs(t) do
      local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.push()
        love.graphics.scale(scale + 0.004 * math.sin(s.time * 5 + r))
        love.graphics.translate(x, y)
        love.graphics.scale(0.75)
        -- draw icon inside circle cutout
        love.graphics.stencil(stencilFunc, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        love.graphics.push() -- guard against patch's transformations
        local ok, err = pcall(patch.icon, s.time, s)
        love.graphics.pop()
        if not ok then
          love.graphics.setColor(1, 1, 1, 1)
          selector.defaultIcon(q, r)
          log(err)
        end
        love.graphics.setStencilTest()
        love.graphics.setLineWidth(0.1)
        love.graphics.setColor(colorScheme.frame)
        love.graphics.circle('line', 0, 0, 1)
      love.graphics.pop()
    end
  end
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
