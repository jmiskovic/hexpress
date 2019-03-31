local patch = {}

local sampler = require('sampler')
local hexgrid = require('hexgrid')
local hexpad = require('hexpad')
local efx = require('efx')
local l = require('lume')

local colorScheme = {
  shade          = {l.rgba(0x00000050)},
  light          = {l.rgba(0xffffff50)},
  membraneShade1 = {l.rgba(0xccb594ff)},
  membrane       = {l.rgba(0xc9bba3ff)},
  membraneShade2 = {l.rgba(0x41413fff)},
  rim            = {l.rgba(0x606060ff)},
  stick          = {l.rgba(0xc0a883ff)},
  background     = {l.rgba(0x744c2aff)},
}

function patch.load()
  patch.layout = { -- elements are listed in draw order (farthest to nearest)
    {path='patches/tabla/dira.ogg', type='tabla', x=-0.732, y= 0.594, r= 0.40},
    {path='patches/tabla/gaa.ogg',  type='tabla', x= 0.070, y= 0.633, r= 0.40},
    {path='patches/tabla/ti.ogg',   type='tabla', x= 1.143, y= 0.174, r= 0.40},
    {path='patches/tabla/tii.ogg',  type='tabla', x= 0.352, y=-0.034, r= 0.40},
    {path='patches/tabla/ka.ogg',   type='tabla', x=-1.260, y=-0.049, r= 0.40},
    {path='patches/tabla/kaa.ogg',  type='tabla', x=-0.466, y=-0.073, r= 0.40},
    {path='patches/tabla/kii.ogg',  type='tabla', x= 0.896, y=-0.690, r= 0.40},
    {path='patches/tabla/taa.ogg',  type='tabla', x= 0.083, y=-0.724, r= 0.40},
    {path='patches/tabla/tun.ogg',  type='tabla', x=-0.768, y=-0.664, r= 0.40},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 5 },
  }
  patch.droneLayout = { -- elements are listed in draw order (lowest to highest)
    {path='patches/tabla/drone.ogg',  type='membrane', x=0.693, y=-0.672, r= 0.20},
    envelope = { attack = .0, decay = 0, sustain = 1, release = 5 },
  }

  for i,element in ipairs(patch.layout) do
    element.note = i * 3 --by spreading out note indexes we allow for more pitch range on single sample
    element.oscM = 0 --oscilation magnitude
    element.oscA = 0 --oscilation angle
  end
  patch.drums = sampler.new(patch.layout)
  patch.drones = sampler.new(patch.droneLayout)
  love.graphics.setBackgroundColor(colorScheme.background)
  patch.tones = {}
  love.graphics.setBackgroundColor(colorScheme.background)
end

function patch.interpretLayout(s, layout, id, touch)
  local x, y = love.graphics.inverseTransformPoint(touch[1], touch[2])
  for i = #layout, 1, -1 do
    local element = patch.layout[i]
    if l.distance(x, y, element.x, element.y, true) < element.r^2 then
      touch.noteRetrigger = false
      if not patch.tones[id] or patch.tones[id] ~= element then
        patch.tones[id] = element
        touch.noteRetrigger = true
        element.noteVariation = element.note
        element.oscA = l.angle(x, y, element.x, element.y)
        element.oscM = l.distance(x, y, element.x, element.y)
      end
      touch.note = element.noteVariation
      touch.location = {x * 0.7, 0.5}
      break
    end
  end
end

function patch.interpret(s)
  for id,touch in pairs(s.touches) do
    patch.interpretLayout(s, patch.layout, id, touch)
  end
  -- clean up released tones
  for id, touch in pairs(patch.tones) do
    if not s.touches[id] then
      patch.tones[id] = nil
    end
  end
end

function patch.process(s)
  patch.interpret(s)
  efx.reverb.decaytime = l.remap(s.tilt.lp[1], 0.1, -0.5, 0.5, 4)
  patch.drums:processTouches(s.dt, s.touches)
  return s
end

local selected = 1

function patch.draw(s)
  love.graphics.setLineWidth(0.02)

  for i, element in ipairs(patch.layout) do
    touched = false
    for id, touch in pairs(patch.tones) do
      if element == touch then
        touched = true
        break
      end
    end
    if element.type == 'tabla' then
      love.graphics.setColor(colorScheme.shade)
      love.graphics.ellipse('fill', element.x * 0.95, element.y + 0.05, element.r, element.r * .95)
      love.graphics.setColor(colorScheme.membraneShade1)
      love.graphics.ellipse('fill', element.x, element.y, element.r, element.r * .95)
      love.graphics.setColor(colorScheme.membrane)
      love.graphics.ellipse('fill', element.x, element.y, element.r * .8, element.r * .8 * .95)
      love.graphics.setColor(colorScheme.membraneShade2)
      love.graphics.ellipse('fill', element.x, element.y, element.r * .3, element.r * .3 * .95)
      love.graphics.setColor(colorScheme.rim)
      local rimRadius = touched and element.r - 0.01 or element.r
      love.graphics.ellipse('line', element.x, element.y, rimRadius, rimRadius * .95)
    elseif element.type == 'block' then
      love.graphics.setColor(colorScheme.light)
      love.graphics.circle('fill', element.x, element.y, touched and element.r - 0.01 or element.r)
    end
--[[ for arranging layout of elements (on desktop)
    if i == selected then
      love.graphics.setColor(0, 1, 0, 0.3)
      love.graphics.circle('fill', element.x, element.y, element.r)
      if love.mouse.isDown(1) then
        element.x, element.y = love.graphics.inverseTransformPoint(love.mouse.getX(), love.mouse.getY())
      end
    end
--]]
  end
end

--[[ for arranging layout of elements (on desktop)
function love.keypressed(key)
  if key == 'tab' then
    selected = (selected % #patch.layout) + 1
  end
  if key == 'return' then
    for i,v in ipairs(patch.layout) do
      print(string.format('x=% 1.3f, y=% 1.3f, r=% 1.2f},',v.x, v.y, v.r))
    end
  end
  if key == '=' then
    patch.layout[selected].r = patch.layout[selected].r * 1.02
  elseif key == '-' then
    patch.layout[selected].r = patch.layout[selected].r / 1.02
  end
end
--]]

function patch.icon(time)
  local speed = 4
  love.graphics.setColor(colorScheme.background)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- drum
  love.graphics.setColor(colorScheme.shade)
  love.graphics.rectangle('fill', -1.22, 0, 2.44, 1)
  love.graphics.ellipse('fill', 0, 1, 1.22, 0.6, 22, 0.6 * .95)
  love.graphics.setColor(colorScheme.membrane)
  love.graphics.ellipse('fill', 0, 0, 1.2, 0.6, 1.2, 0.6 * .95)
  love.graphics.setLineWidth(0.08)
  love.graphics.setColor(colorScheme.rim)
  love.graphics.ellipse('line', 0, 0, 1.2, 0.6, 1.2, 0.6 * .95)
  -- left stick
 love.graphics.setColor(colorScheme.stick)
  love.graphics.push()
    love.graphics.translate(-2.2, 0.3)
    love.graphics.rotate(math.pi / 8 - math.pi / 4 * math.abs(math.sin(speed * time)))
    love.graphics.line(-0.5, 0, 1.7, -0.9)
    love.graphics.circle('fill', 1.7, -0.9, 0.07)
  love.graphics.pop()
  -- other left stick
  love.graphics.push()
    love.graphics.translate(2.2, 0.3)
    love.graphics.rotate(-math.pi / 8 + math.pi / 4 * math.abs(math.cos(speed * time)))
    love.graphics.line(0.5, 0, -1.7, -0.9)
    love.graphics.circle('fill', -1.7, -0.9, 0.07)
  love.graphics.pop()
end

return patch