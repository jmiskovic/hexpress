local patch = {}

local sampler = require('sampler')
local hexgrid = require('hexgrid')
local hexpad = require('hexpad')
local efx = require('efx')
local l = require('lume')

local colorScheme = {
  cymbal   = {l.rgba(0xccad00ff)},
  shade    = {l.rgba(0x00000050)},
  light    = {l.rgba(0xffffff50)},
  membrane = {l.rgba(0xd7d0aeff)},
  rim      = {l.rgba(0x606060ff)},
  stick    = {l.rgba(0xc0a883ff)},
  background = {l.rgba(0x38404a)},
}

function patch.load()
  patch.layout = { -- elements are listed in draw order (lowest to highest)
    {path='patches/garage/groovy/kick_1.ogg',       type='block',    x= 0.022, y= 0.417, r= 1.06, pitchVariation=0.8},
    {path='patches/garage/groovy/sidestick.ogg',    type='block',    x=-0.875, y= 0.500, r= 0.29, pitchVariation=0.8},
    {path='patches/garage/groovy/snare_2.ogg',      type='membrane', x=-0.356, y= 0.111, r= 0.59, pitchVariation=0.8},
    {path='patches/garage/groovy/low_tom.ogg',      type='membrane', x= 0.697, y= 0.128, r= 0.45, pitchVariation=0.8},
    {path='patches/garage/groovy/mid_tom.ogg',      type='membrane', x= 0.347, y=-0.394, r= 0.33, pitchVariation=0.8},
    {path='patches/garage/groovy/high_tom.ogg',     type='membrane', x=-0.294, y=-0.344, r= 0.32, pitchVariation=0.8},
    {path='patches/garage/groovy/extra_cymbal.ogg', type='cymbal',   x=-0.094, y=-0.694, r= 0.30, pitchVariation=0.1},
    {path='patches/garage/groovy/splash.ogg',       type='cymbal',   x=-1.006, y=-0.081, r= 0.31, pitchVariation=0.1},
    {path='patches/garage/groovy/extra_splash.ogg', type='cymbal',   x= 0.933, y= 0.672, r= 0.30, pitchVariation=0.1},
    {path='patches/garage/groovy/hat_open.ogg',     type='cymbal',   x= 1.167, y=-0.083, r= 0.55, pitchVariation=0.05},
    {path='patches/garage/groovy/hat_closed.ogg',   type='block',    x= 1.161, y=-0.081, r= 0.40, pitchVariation=0.5},
    {path='patches/garage/groovy/ride.ogg',         type='cymbal',   x= 0.622, y=-0.700, r= 0.46, pitchVariation=0.05},
    {path='patches/garage/groovy/ride_bell.ogg',    type='block',    x= 0.620, y=-0.703, r= 0.17, pitchVariation=0.1},
    {path='patches/garage/groovy/crash_1.ogg',      type='cymbal',   x=-0.756, y=-0.581, r= 0.40, pitchVariation=0.05},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.6 },
  }

  for i,element in ipairs(patch.layout) do
    element.note = i * 3 --by spreading out note indexes we allow for more pitch range on single sample
    element.oscM = 0 --oscilation magnitude
    element.oscA = 0 --oscilation angle
  end
  patch.drums = sampler.new(patch.layout)
  love.graphics.setBackgroundColor(colorScheme.background)
  patch.tones = {}
  love.graphics.setBackgroundColor(colorScheme.background)
end

function patch.interpret(s)
  for id,touch in pairs(s.touches) do
    local x, y = love.graphics.inverseTransformPoint(touch[1], touch[2])
    for i = #patch.layout, 1, -1 do
      local element = patch.layout[i]
      if l.distance(x, y, element.x, element.y, true) < element.r^2 then
        touch.noteRetrigger = false
        if not patch.tones[id] or patch.tones[id] ~= element then
          patch.tones[id] = element
          touch.noteRetrigger = true
          -- insert random pitch variation on each new note
          element.noteVariation = element.note + (0.5 - math.random()) * element.pitchVariation
          element.oscA = l.angle(x, y, element.x, element.y)
          element.oscM = l.distance(x, y, element.x, element.y)
        end
        touch.note = element.noteVariation
        touch.location = {x * 0.7, 0.5}
        break
      end
    end
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

function drawCymbal(s, element)
  love.graphics.push()
    love.graphics.translate(element.x, element.y)
    -- emulate cymbal swinging
    love.graphics.rotate(element.oscA)
    love.graphics.scale(1 - 0.1 * element.oscM * (math.sin(5 * s.time) + 1), 1)
    love.graphics.rotate(-element.oscA)
    element.oscM = element.oscM * (1 - 0.99 * s.dt)
    local aoff = element.oscM * math.cos(5 * s.time) -- reflections angle offset
    -- cymbal surface
    love.graphics.setColor(colorScheme.cymbal)
    love.graphics.circle('fill', 0, 0, element.r)
    love.graphics.setColor(colorScheme.light)
    -- cymbal outline
    love.graphics.circle('line', 0, 0, element.r - 0.01)
    -- light reflections
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
    -- center bell
    love.graphics.circle('fill', 0, 0, element.r * 0.2)
    love.graphics.setColor(colorScheme.light)
    love.graphics.circle('fill', 0, 0, element.r * 0.2)
  love.graphics.pop()
end

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
  love.graphics.ellipse('fill', 0, 1, 1.22, 0.6)
  love.graphics.setColor(colorScheme.membrane)
  love.graphics.ellipse('fill', 0, 0, 1.2, 0.6)
  love.graphics.setLineWidth(0.08)
  love.graphics.setColor(colorScheme.rim)
  love.graphics.ellipse('line', 0, 0, 1.2, 0.6)
  -- left stick
 love.graphics.setColor(colorScheme.stick)
  love.graphics.push()
    love.graphics.translate(-2, -0.5)
    love.graphics.rotate(math.pi / 8 - math.pi / 4 * math.abs(math.sin(speed * time)))
    love.graphics.line(-0.5, 0, 1.7, 0)
    love.graphics.circle('fill', 1.7, 0, 0.07)
  love.graphics.pop()
  -- other left stick
  love.graphics.push()
    love.graphics.translate(2, -0.5)
    love.graphics.rotate(-math.pi / 8 + math.pi / 4 * math.abs(math.cos(speed * time)))
    love.graphics.line(0.5, 0, -1.7, 0)
    love.graphics.circle('fill', -1.7, 0, 0.07)
  love.graphics.pop()
end

return patch