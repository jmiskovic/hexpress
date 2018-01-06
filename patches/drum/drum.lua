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
  background = {0,0,0},
}

local selected = 1

function patch.load()
  patch.layout = { -- elements are listed in draw order (lowest to highest)
--[[
    {path='patches/drum/rock/kick.ogg',         note = 0,  x= 0.003, y= 0.286, r= 0.577},
    {path='patches/drum/rock/hat_closed.ogg',   note = 2,  x=-1.361, y= 0.339, r= 0.428},
    {path='patches/drum/rock/hat_pedal.ogg',    note = 3,  x=-1.344, y= 0.181, r= 0.266},
    {path='patches/drum/rock/hat_open.ogg',     note = 4,  x=-1.344, y= 0.117, r= 0.191},
    {path='patches/drum/rock/sidestick.ogg',    note = 6,  x=-0.689, y= 0.281, r= 0.294},
    {path='patches/drum/rock/snare_1.ogg',      note = 5,  x=-0.608, y= 0.078, r= 0.345},
    {path='patches/drum/rock/floor_tom.ogg',    note = 9,  x= 0.750, y= 0.017, r= 0.351},
    {path='patches/drum/rock/high_tom.ogg',     note = 12, x=-0.536, y=-0.428, r= 0.283},
    {path='patches/drum/rock/mid_high_tom.ogg', note = 11, x=-0.069, y=-0.542, r= 0.288},
    {path='patches/drum/rock/mid_low_tom.ogg',  note = 10, x= 0.397, y=-0.358, r= 0.300},
    {path='patches/drum/rock/crash_1.ogg',      note = 7,  x=-1.128, y=-0.539, r= 0.464},
    {path='patches/drum/rock/crash_2.ogg',      note = 8,  x= 1.297, y=-0.397, r= 0.512},
--]]
    {path='patches/drum/groovy/kick_1.ogg',       x= 0.022, y= 0.417, r= 0.67, type='block'},
    {path='patches/drum/groovy/sidestick.ogg',    x=-0.764, y= 0.336, r= 0.29, type='block'},
    {path='patches/drum/groovy/snare_2.ogg',      x=-0.597, y= 0.056, r= 0.42, type='membrane'},
    {path='patches/drum/groovy/low_tom.ogg',      x= 0.656, y= 0.239, r= 0.38, type='membrane'},
    {path='patches/drum/groovy/mid_tom.ogg',      x= 0.353, y=-0.244, r= 0.31, type='membrane'},
    {path='patches/drum/groovy/high_tom.ogg',     x=-0.211, y=-0.342, r= 0.32, type='membrane'},
    {path='patches/drum/groovy/extra_cymbal.ogg', x=-0.294, y=-0.781, r= 0.30, type='cymbal'},
    {path='patches/drum/groovy/splash.ogg',       x=-1.178, y=-0.128, r= 0.31, type='cymbal'},
    {path='patches/drum/groovy/extra_splash.ogg', x= 0.192, y=-0.689, r= 0.30, type='cymbal'},
    {path='patches/drum/groovy/hat_open.ogg',     x= 1.100, y= 0.150, r= 0.40, type='cymbal'},
    {path='patches/drum/groovy/hat_closed.ogg',   x= 1.108, y= 0.150, r= 0.32, type='block'},
    {path='patches/drum/groovy/ride.ogg',         x= 0.881, y=-0.592, r= 0.51, type='cymbal'},
    {path='patches/drum/groovy/ride_bell.ogg',    x= 0.886, y=-0.600, r= 0.23, type='block'},
    {path='patches/drum/groovy/crash_1.ogg',      x=-0.756, y=-0.581, r= 0.41, type='cymbal'},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.6 },
  }

  for i,element in ipairs(patch.layout) do
    element.note = i * 3
  end
  patch.drums = sampler.new(patch.layout)
  love.graphics.setBackgroundColor(colorScheme.background)
  patch.tones = {}
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
        end
        touch.note = element.note + (0.5 - math.random()) * 2
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
  efx.reverb.decaytime = l.remap(s.tilt.lp[2], 0.1, -0.5, 0.5, 4)
  patch.drums:processTouches(s.dt, s.touches)
  return s
end

function drawCymbal(s, element)
  love.graphics.push()
    local aoff = touched and math.cos(5 * s.time) or 0 -- angle offset
    love.graphics.translate(element.x, element.y)
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
      love.graphics.circle('fill', element.x, element.y, element.r)
    end
---[[
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

---[[
function love.keypressed(key)
  if key == 'tab' then
    selected = (selected % #patch.layout) + 1
  end
  if key == 'return' then
    for i,v in ipairs(patch.layout) do
      print(string.format('x=% 1.3f, y=% 1.3f, r=% 1.2f, ',v.x, v.y, v.r))
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
  love.graphics.setColor(0.2, 0.4, 0.7)
  love.graphics.circle('fill', 0, 0, 0.7)
end

return patch