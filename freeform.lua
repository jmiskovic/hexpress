-- implementation of freeform note layout based on list of trigger areas

local l = require('lume')

local freeform = {}
freeform.__index = freeform

function freeform.new(triggers)
  local self = setmetatable(
    {layout= triggers,
     active= {}},
    freeform)

  for i, element in ipairs(triggers) do
    element.note = i
    if element.type == 'cymbal' then
        element.oscM = 0 --oscillation magnitude
        element.oscA = 0 --oscillation angle
    end
  end
  return self
end

local colorScheme = {
  -- drumset
  cymbal       = {l.rgba(0xccad00ff)},
  shade        = {l.rgba(0x00000050)},
  brightCymbal = {l.rgba(0xffffff50)},
  membrane     = {l.rgba(0xd7d0aeff)},
  rim          = {l.rgba(0x606060ff)},
  -- hex pads:    pad color             frame color
  green    = {{l.rgba(0x2a6222ff)}, {l.rgba(0x559644ff)}},
  red      = {{l.rgba(0x91251cff)}, {l.rgba(0xd83a2cff)}},
  orange   = {{l.rgba(0xa84c0cff)}, {l.rgba(0xf47e35ff)}},
  blue     = {{l.rgba(0x264452ff)}, {l.rgba(0x53a691ff)}},
  gray    = {{l.rgba(0x825e4cff)}, {l.rgba(0xc0957cff)}},

}


function freeform:interpret(s)
  for id,touch in pairs(s.touches) do
    local x, y = love.graphics.inverseTransformPoint(touch[1], touch[2])
    -- find closes element to touch position, retrigger as necessary
    for i = #self.layout, 1, -1 do -- reverse iteration, to trigger topmost elements first
      local element = self.layout[i]
      if l.distance(x, y, element.x, element.y, true) < element.r^2 then
        touch.noteRetrigger = false
        -- new tone
        if not self.active[id] or self.active[id] ~= element then
          self.active[id] = element
          touch.noteRetrigger = true
          if element.type == 'cymbal' then -- initial stimulus for cymbal wobble
            element.oscA = l.angle(x, y, element.x, element.y)
            element.oscM = l.distance(x, y, element.x, element.y)
          end
        end
        touch.note = element.note
        touch.location = {x * 0.7, 0.5}
        break
      end
    end
  end
  -- clean up released touches
  for id, touch in pairs(self.active) do
    if not s.touches[id] then
      self.active[id] = nil
    end
  end
end


function freeform:draw(s)
  love.graphics.setLineWidth(0.02)
  for i, element in ipairs(self.layout) do
    local touched = false
    -- ouch, O(N^2) on each frame (but there should only be _handful_ of touches)
    for id, touch in pairs(self.active) do
      if element == touch then
        touched = true
        break
      end
    end
    if element.type == 'membrane' then
      love.graphics.setColor(colorScheme.shade)
      love.graphics.circle('fill', element.x * 0.95, element.y + 0.05, element.r)
      love.graphics.setColor(colorScheme.membrane)
      love.graphics.circle('fill', element.x, element.y, element.r)
      love.graphics.setColor(colorScheme.rim)
      love.graphics.circle('line', element.x, element.y, touched and element.r - 0.01 or element.r)
    elseif element.type == 'cymbal' then
      drawCymbal(s, element)
    elseif element.type == 'block' then
      love.graphics.setColor(colorScheme.brightCymbal)
      love.graphics.circle('fill', element.x, element.y, touched and element.r - 0.01 or element.r)
    elseif element.type == 'hex' then
        love.graphics.push()
        love.graphics.setColor(colorScheme[element.color][2])
        love.graphics.translate(element.x, element.y)
        love.graphics.rotate(-math.pi/12)
        love.graphics.scale(element.r * 0.91)
        love.graphics.polygon('fill', roundhex)
        if not touched then
          love.graphics.setColor(colorScheme[element.color][1])
          love.graphics.translate(0, -0.1)
          love.graphics.scale(0.98)
          love.graphics.polygon('fill', roundhex)
        end
        love.graphics.pop()
    end
  end
end


function drawCymbal(s, element)
  love.graphics.push()
    love.graphics.translate(element.x, element.y)
    -- emulate cymbal wobbling when hit
    love.graphics.rotate(element.oscA)
    love.graphics.scale(1 - 0.1 * element.oscM * (math.sin(5 * s.time) + 1), 1)
    love.graphics.rotate(-element.oscA)
    element.oscM = element.oscM * (1 - 0.99 * s.dt)
    local aoff = element.oscM * math.cos(5 * s.time) -- reflections angle offset
    -- cymbal surface
    love.graphics.setColor(colorScheme.cymbal)
    love.graphics.circle('fill', 0, 0, element.r)
    love.graphics.setColor(colorScheme.brightCymbal)
    -- cymbal outline
    love.graphics.circle('line', 0, 0, element.r - 0.01)
    ---[[ light reflections
    for j = 1, 5 do
      love.graphics.push()
        if j % 2 == 0 then
          love.graphics.rotate(j + aoff * math.pi / 12)
        else
          love.graphics.rotate(j - aoff * math.pi / 12)
        end
        local w = math.pi / 50
        love.graphics.arc('fill', 0, 0, element.r, -w, w)
        love.graphics.arc('fill', 0, 0, element.r, math.pi + w, math.pi - w)
      love.graphics.pop()
    end
    -- surface grooves
    love.graphics.setColor(colorScheme.cymbal)
    for r = element.r * 0.2, element.r - 0.03, 0.03 do
      love.graphics.circle('line', 0, 0, r)
    end
    --]]
    -- center bell
    love.graphics.circle('fill', 0, 0, element.r * 0.2)
    love.graphics.setColor(colorScheme.brightCymbal)
    love.graphics.circle('fill', 0, 0, element.r * 0.2)
  love.graphics.pop()
end

--[[ freeform layout editor
local selected = 1

draw
    if i == selected then
      love.graphics.setColor(0, 1, 0, 0.3)
      love.graphics.circle('fill', element.x, element.y, element.r)
      if love.mouse.isDown(1) then
        element.x, element.y = love.graphics.inverseTransformPoint(love.mouse.getX(), love.mouse.getY())
      end
    end

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

return freeform
