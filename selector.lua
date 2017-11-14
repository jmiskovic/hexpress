local selector = {}

require('autotable')
local hexgrid = require('hexgrid')

local radius = 0    -- to be inflated while loading patches
local scale = 100
local gap = 30
local cx, cy = 0, 0

local patches = table.autotable(2)

function selector.load(path)
  local i = 1
  local fileList = love.filesystem.getDirectoryItems(path)
  for q, r in hexgrid.spiralIter(0, 0, math.huge) do
    if i > #fileList then
      break
    end
    local requirePath = path .. '/' .. string.gsub(fileList[i], '.lua$','')
    local status, lfs = pcall(require, requirePath)
    if(status) then
      patches[q][r] = lfs
      log('success with', name)
    else
      log('no luck with', path..'/'..name)
    end
    radius = hexgrid.distanceFromCenter(q, r)
    i = i+1
  end
end

function selector.place(x, y)
  cx, cy = x, y
end

function selector.update(dt)
  for _,id in ipairs(love.touch.getTouches()) do
    local x, y = love.touch.getPosition(id)
    local q, r = hexgrid.pixelToHex(x, y, cx, cy, scale + gap)

    if hexgrid.distanceFromCenter(q,r) < radius + 1 then log(q,r, hexgrid.distanceFromCenter(q,r)) end
  end
end

function selector.draw()
  for q, t in pairs(patches) do
    for r, patch in pairs(t) do
      local x, y = hexgrid.hexToPixel(q, r, cx, cy, scale + gap)
      love.graphics.translate(x, y)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.stencil(stencilFunc, "replace", 1)
      love.graphics.setStencilTest("greater", 0)
      love.graphics.circle('fill', 0, 0, scale)
      love.graphics.setStencilTest()
      love.graphics.origin()
    end
  end
end

function stencilFunc()
  love.graphics.circle('fill', 0, 0, scale)
end

return selector

