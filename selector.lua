local l = require('lume')

-- this is main screen for selecting between patches
local selector = {}

local colorScheme = {
  background = {l.rgba(0x2d2734ff)},
  frame      = {l.rgba(0xffffff22)},
  shadow     = {l.rgba(0x00000040)}
}

require('autotable')
local hexgrid = require('hexgrid')
local faultyPatch = require('faultyPatch')
local radius = 0   -- number of rings of icons around central icon, (inflated to actual size while loading patches)
local scale = 0    -- fit about this many icons along vertical screen space

local patches = {}


function selector.load()
  love.graphics.setBackgroundColor(colorScheme.background)
  patches = table.autotable(2)
  local i = 1
  -- try to load all patches in directory, store them in hexagonal spiral
  local fileList = love.filesystem.getDirectoryItems('patches')
  for q, r in hexgrid.spiralIter(0, 0, math.huge) do
    -- skip everything outside the y-range for better layout
    x, y = hexgrid.hexToPixel(q, r)
    if math.abs(y) > 3 then
      i = i+1
    else
      if #fileList == 0 then
        break
      end
      local iterName = fileList[#fileList]
      fileList[#fileList] = nil
      local loadPath = 'patches/' .. iterName .. '/' .. iterName
      local m, err = l.hotswap(loadPath)
      if m then
        patches[q][r] = m
      else
        log(err)
        patches[q][r] = faultyPatch.new(err) -- if cannot load, show error icon and description
      end
      radius = hexgrid.distanceFromCenter(q, r)
      i = i+1
    end
  end
  radius = radius - 0.5 -- TODO: improve 16:9 screen utilization and remove line
  scale = 1 / (2 * radius + 0.7)
  return selector
end

function selector.checkTouch(x, y)
  love.graphics.push()
  love.graphics.scale(scale)
  x, y = love.graphics.inverseTransformPoint(x, y)
  love.graphics.pop()
  local q, r = hexgrid.pixelToHex(x, y)

  if hexgrid.distanceFromCenter(q,r) < radius + 1 then
    local selected = patches[q][r]
    if selected then
      loadPatch(selected)
      return true
    end
  end
  return false
end

function selector:process(s)
  -- if sceen is touched, find patch icon closest to touch and load that patch
  for _,touch in pairs(s.touches) do
    if selector.checkTouch(touch[1], touch[2]) then
      break
    end
  end
  if love.mouse.isDown(1) then
    selector.checkTouch(love.mouse.getPosition())
  end
end

function selector:draw(s)
  for q, t in pairs(patches) do
    for r, patch in pairs(t) do
      local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.push()
        -- swaying of individual icons
        love.graphics.scale(scale + 0.004 * math.sin(s.time * 5 + r))
        love.graphics.translate(x, y)
        -- space between icons
        love.graphics.scale(0.75)
        -- draw shadow
        love.graphics.setColor(colorScheme.shadow)
        love.graphics.ellipse ('fill', 0, 0.35, 0.95, 0.8)
        -- draw icon inside cutout shape defined by stencilFunc
        love.graphics.stencil(stencilFunc, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        if patch.icon then
          love.graphics.push() -- guard against patch's transformations
          local ok, err = pcall(patch.icon, s.time, s)
          love.graphics.pop()
          if not ok then log(err) end
        else
          love.graphics.setColor(1, 1, 1, 1)
          selector.defaultIcon(q, r)
        end
        love.graphics.setStencilTest() -- disable stencil
        -- draw circular frame around icon
        love.graphics.setLineWidth(0.1)
        love.graphics.setColor(colorScheme.frame)
        love.graphics.circle('line', 0, 0, 1)
      love.graphics.pop()
    end
  end
  --selector.drawLogo(s.tilt.lp)
end


-- if patch doesn't have icon, use single color unique to patch name
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


-- icon cutout shape
function stencilFunc()
  love.graphics.circle('fill', 0, 0, 1)
end


--selector.logo = love.graphics.newImage('media/hi-res_icon.png')

function selector.drawLogo(tilt)
  local height = selector.logo:getHeight()
  local count = 5
  love.graphics.push()
  love.graphics.translate(1.3, 0.8)
  love.graphics.scale(0.3)
  love.graphics.setColor(colorScheme.frame)
  love.graphics.circle('fill', 0, 0, 1.05)
  love.graphics.stencil(stencilFunc, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  love.graphics.scale(2 / height)
  for i = 1, count do
    love.graphics.translate(-tilt[1] * 0.2 * height * i / count, -tilt[2] * 0.2 * height * i / count)
    love.graphics.setColor(1,1,1, i/count)
    love.graphics.draw(selector.logo, -selector.logo:getWidth()/2, -height/2)
  end
  love.graphics.setStencilTest() -- disable stencil
  love.graphics.pop()
end

return selector
