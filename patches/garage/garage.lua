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
    {path='patches/garage/acustic/CyCdh_K3Kick-03.ogg',       type='block',    x= 0.052, y= 0.839, r= 1.06},
    {path='patches/garage/acustic/CYCdh_LudSdStC-04.ogg',     type='block',    x= 0.461, y= 0.018, r= 0.57},
    {path='patches/garage/acustic/CYCdh_K2room_Snr-01.ogg',   type='membrane', x=-0.461, y=-0.005, r= 0.75},
    {path='patches/garage/acustic/CYCdh_K2room_Snr-04.ogg',   type='block',    x=-0.464, y= 0.073, r= 0.53},
    {path='patches/garage/acustic/CyCdh_K3Tom-05.ogg',        type='membrane', x= 0.776, y= 0.109, r= 0.48},
    {path='patches/garage/acustic/CYCdh_Kurz01-Tom03.ogg',    type='membrane', x= 0.268, y=-0.367, r= 0.40},
    {path='patches/garage/acustic/CYCdh_Kurz03-Tom03.ogg',    type='membrane', x=-0.427, y=-0.307, r= 0.32},
    {path='patches/garage/acustic/CYCdh_VinylK1-Tamb.ogg',    type='block',    x= 0.906, y=-0.466, r= 0.40},
    {path='patches/garage/acustic/CYCdh_VinylK4-China.ogg',   type='cymbal',   x=-0.187, y=-0.807, r= 0.37},
    {path='patches/garage/acustic/CYCdh_TrashD-02.ogg',       type='cymbal',   x=-0.786, y=-0.659, r= 0.34},
    {path='patches/garage/acustic/CYCdh_K4-Trash10.ogg',      type='cymbal',   x=-1.180, y=-0.378, r= 0.37},
    {path='patches/garage/acustic/KHats_Open-07.ogg',         type='cymbal',   x= 1.299, y= 0.161, r= 0.35},
    {path='patches/garage/acustic/CYCdh_K2room_ClHat-05.ogg', type='cymbal',   x= 1.112, y=-0.531, r= 0.47},
    {path='patches/garage/acustic/CYCdh_K2room_ClHat-01.ogg', type='block',    x= 1.047, y=-0.701, r= 0.28},
    {path='patches/garage/acustic/CYCdh_VinylK4-Ride01.ogg',  type='cymbal',   x= 0.448, y=-0.742, r= 0.36},
    {path='patches/garage/acustic/CYCdh_Kurz01-Ride01.ogg',   type='block',    x= 0.448, y=-0.737, r= 0.17},
    {path='patches/garage/acustic/CyCdh_K3Crash-02.ogg',      type='cymbal',   x=-1.312, y= 0.211, r= 0.32},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 1.0 },
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
    love.graphics.setColor(colorScheme.light)
    love.graphics.circle('fill', 0, 0, element.r * 0.2)
  love.graphics.pop()
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