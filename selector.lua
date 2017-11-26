local l = require('lume')

local selector = {}
local logo

local colorScheme = {
  {0.53, 0.35, 0.34}, -- orange
  {0.53, 0.45, 0.34}, -- yellow
  {0.31, 0.38, 0.55}, -- blue
  {0.31, 0.53, 0.47}, -- green
  {0.52, 0.31, 0.55}, -- purple
  darker        = {l.color('#2e2e3baa')},
  background    = {l.color('#28253dff')},
}

require('autotable')
local hexgrid = require('hexgrid')
local faultyPatch = require('faultyPatch')
local radius = 0    -- inflated to actual size while loading patches
local scale = 100
local gap = 1.3
local cx, cy = 0, 0

local patches = {}
local frame

function selector.load(path, cx, cy)
  patches = table.autotable(2)
  logo = love.graphics.newImage('logo.png')
  cx = cx or 0
  cy = cy or 0
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
  scale = cy / radius / 8

  frame = love.graphics.newCanvas(scale * 2, scale * 2, {width=scale * 2, height=scale * 2, format='srgba8'})
  love.graphics.setCanvas(frame)
  love.graphics.translate(scale, scale)
  love.graphics.scale(scale)
  love.graphics.setLineWidth(0.03)
  love.graphics.setColor(colorScheme.darker)
  love.graphics.circle('line', 0, 0, 0.8)
  love.graphics.setCanvas()
end

function selector.process(s)
  for _,id in ipairs(love.touch.getTouches()) do
    local x, y = love.touch.getPosition(id)
    love.graphics.scale(scale * gap)
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
  love.graphics.setBackgroundColor(colorScheme.background)
  for q, t in pairs(patches) do
    for r, patch in pairs(t) do
      local x, y = hexgrid.hexToPixel(q, r)
      love.graphics.push()
        love.graphics.scale(scale * gap)
        love.graphics.translate(x, y)
        love.graphics.scale(1 / gap)
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
        -- frame
        love.graphics.scale(1/scale)
        love.graphics.scale(1.3)
        love.graphics.setColor(1, 1, 1, 1)
        --love.graphics.
        selector.fake3d(s.tilt.lp, frame, 0.955, 4)
      love.graphics.pop()
    end
  end
  -- draw the fake 3D logo to encourage interaction with tilt
  local logoSize = 0.2  -- in relation to screen height
  love.graphics.push()
    love.graphics.translate(0, logo:getHeight())
    love.graphics.setColor(1, 1, 1)
    local extrude = l.remap(s.time, 0, 1, 1, 1.1, 'clamp')
    selector.fake3d(s.tilt.lp, logo, extrude, 4, 0)
  love.graphics.pop()
end

function selector.fake3d(tilt, drawable, expandTo, slices, falloff)
  local expandTo = expandTo or 1.5
  local slices = slices or 3
  local falloff = falloff or 0.2
  local fraction = (expandTo - 1) / slices

  for slice = 1, slices do
    love.graphics.push()
      local sX = 3200 * (slice - 1) * fraction   -- sX and sY define distance from center
      local sY = 1200 * (slice - 1) * fraction
      if expandTo < 1 then
        sY = -sY
        sX = -sX
      end
      local x = fraction * l.remap(tilt[1], -0.30,  0.30, -sX, sX)
      local y = fraction * l.remap(tilt[3],  0.60,  0.35, -sY, sY)
      local s = l.remap(slice, 1, slices, 1, expandTo)
      love.graphics.scale(s)
      love.graphics.translate(x, y)
      love.graphics.translate(-drawable:getWidth()/2, -drawable:getHeight()/2)
      love.graphics.setColor(1, 1, 1, math.exp(-falloff * (slice - 1) /slices))
      love.graphics.draw(drawable)
    love.graphics.pop()
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
