local patch = {}

local sampler = require('sampler')
local hexgrid = require('hexgrid')
local hexpad = require('hexpad')
local efx = require('efx')
local l = require('lume')

roundhex = {1.001,0.065,0.984,0.143,0.940,0.254,0.876,0.388,0.798,0.530,0.714,0.668,0.630,0.791,0.556,0.885,0.496,0.938,0.421,0.963,0.302,0.981,0.154,0.991,-0.008,0.995,-0.170,0.991,-0.318,0.981,-0.437,0.963,-0.512,0.938,-0.572,0.885,-0.646,0.791,-0.729,0.668,-0.814,0.530,-0.892,0.388,-0.956,0.254,-1.000,0.143,-1.017,0.065,-1.000,-0.013,-0.956,-0.125,-0.892,-0.258,-0.814,-0.400,-0.729,-0.539,-0.646,-0.662,-0.572,-0.756,-0.512,-0.809,-0.437,-0.834,-0.318,-0.851,-0.170,-0.862,-0.008,-0.866,0.154,-0.862,0.302,-0.851,0.421,-0.834,0.496,-0.809,0.556,-0.756,0.630,-0.662,0.714,-0.539,0.798,-0.400,0.876,-0.258,0.940,-0.125,0.984,-0.013}

local colorScheme = {
           -- pad color             frame color
  green    = {{l.rgba(0x2a6222ff)}, {l.rgba(0x559644ff)}},
  red      = {{l.rgba(0x91251cff)}, {l.rgba(0xd83a2cff)}},
  orange   = {{l.rgba(0xa84c0cff)}, {l.rgba(0xf47e35ff)}},
  blue     = {{l.rgba(0x264452ff)}, {l.rgba(0x53a691ff)}},
  gray    = {{l.rgba(0x825e4cff)}, {l.rgba(0xc0957cff)}},
  background = {l.rgba(0x000000ff)}, --0x171e31ff
}

local colors = {'red', 'green', 'orange', 'blue', 'gray'}

function patch.load()
  patch.layout = { -- elements are listed in draw order (lowest to highest)
    -- each group is single color, and with elements: kick, snare, hihat, crash
    {path=
     'patches/electrobeats/JoelVenomLayerKick.ogg',
     color='gray',    x=-1.404, y= 0.765, r= 0.22},
    {path=
     'patches/electrobeats/OS_DSND_Kick4.ogg',
     color='gray',    x=-0.828, y= 0.689, r= 0.27},
    {path=
     'patches/electrobeats/KickRoleModelz.ogg',
     color='gray',    x=-0.039, y= 0.676, r= 0.28},
    {path=
     'patches/electrobeats/clapwhoops-wrldview.ogg',
     color='gray',    x= 0.696, y= 0.665, r= 0.30},


    {path=
     'patches/electrobeats/DrillSnarev26.ogg',
     color='orange',    x=-1.418, y= 0.222, r= 0.30},
    {path=
     'patches/electrobeats/Teck-percnineteen85.ogg',
     color='orange',    x=-0.935, y=-0.109, r= 0.24},
    {path=
     'patches/electrobeats/PercConga.ogg',
     color='orange',    x=-0.485, y= 0.235, r= 0.27},
    {path=
     'patches/electrobeats/M-TRSnareDark.ogg',
     color='orange',    x= 0.274, y= 0.243, r= 0.17},
    {path=
     'patches/electrobeats/TIGHTMSNARE2.ogg',
     color='orange',    x= 0.879, y= 0.064, r= 0.25},
    {path=
     'patches/electrobeats/revsnare.ogg',
     color='orange',    x= 1.396, y= 0.526, r= 0.36},


    {path=
     'patches/electrobeats/KENNYBEATSCRASH7.ogg',
     color='green',    x=-1.382, y=-0.343, r= 0.23},
    {path=
     'patches/electrobeats/OpenHihat8.ogg',
     color='green',    x=-0.120, y=-0.141, r= 0.24},
    {path=
     'patches/electrobeats/Teck-hihat10.ogg',
     color='green',    x= 0.417, y=-0.324, r= 0.30},
    {path=
     'patches/electrobeats/Teck-openhihatjuice.ogg',
     color='green',    x= 1.391, y=-0.272, r= 0.30},

    {path=
     'patches/electrobeats/MBNarcaticsHit.ogg',
     color='blue',    x=-0.551, y=-0.337, r= 0.14},
    {path=
     'patches/electrobeats/venus-synth.ogg',
     color='blue',    x=-0.885, y=-0.561, r= 0.17},
    {path=
     'patches/electrobeats/polish-synth.ogg',
     color='blue',    x=-1.233, y=-0.776, r= 0.19},
    {path=
     'patches/electrobeats/elastic-synth.ogg',
     color='blue',    x=-0.271, y=-0.535, r= 0.16},
    {path=
     'patches/electrobeats/delayed-synth.ogg',
     color='blue',    x= 0.061, y=-0.756, r= 0.20},

    {path=
     'patches/electrobeats/PercOGKush2.ogg',
     color='red',    x=-0.557, y=-0.737, r= 0.16},
    {path=
     'patches/electrobeats/dish-accent.ogg',
     color='red',    x= 0.481, y=-0.811, r= 0.15},
    {path=
     'patches/electrobeats/NM-LiveFX3.ogg',
     color='red',    x= 0.818, y=-0.611, r= 0.17},
    {path=
     'patches/electrobeats/MBTransFX1.ogg',
     color='red',    x= 1.169, y=-0.776, r= 0.10},

    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.2 },
  }

  for i,element in ipairs(patch.layout) do
    element.note = i * 3 --by spreading out note indexes we allow for more pitch range on single sample
  end
  patch.drums = sampler.new(patch.layout)
  love.graphics.setBackgroundColor(colorScheme.background)
  patch.tones = {}
end

function patch.interpret(s)
  for id,touch in pairs(s.touches) do
    local x, y = love.graphics.inverseTransformPoint(touch[1], touch[2])
    -- find closes element to touch position, retrigger as necessary
    for i = #patch.layout, 1, -1 do
      local element = patch.layout[i]
      local radius2 = (element.r * 1.2)^2
      if l.distance(x, y, element.x, element.y, true) < radius2 then
        touch.noteRetrigger = false
        if not patch.tones[id] or patch.tones[id] ~= element then
          patch.tones[id] = element
          touch.noteRetrigger = true
        end
        touch.note = element.note
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
  efx.reverb.decaytime  = l.remap(s.tilt.lp[1],  0.1, -0.5, 0.5, 4)
  patch.drums:processTouches(s.dt, s.touches)
  return s
end

local selected = 1

function patch.draw(s)
  -- ouch, O(N^2) on each frame
  for i, element in ipairs(patch.layout) do
    touched = false
    for id, touch in pairs(patch.tones) do
      if element == touch then
        touched = true
        break
      end
    end

    love.graphics.push()
    love.graphics.setColor(colorScheme[element.color][2])
    love.graphics.translate(element.x, element.y)
    love.graphics.rotate(-math.pi/12)
    love.graphics.scale(element.r)
    love.graphics.polygon('fill', roundhex)
    if not touched then
      love.graphics.setColor(colorScheme[element.color][1])
      love.graphics.translate(0, -0.1)
      love.graphics.scale(0.98)
      love.graphics.polygon('fill', roundhex)
    end
    love.graphics.pop()

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
  if key == '`' then
    selected = ((selected-1) % #patch.layout)
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
  if key == '.' then
    patch.layout[selected].r = patch.layout[selected].r * 1.1
  elseif key == ',' then
    patch.layout[selected].r = patch.layout[selected].r / 1.1
  end

end
--]]


function patch.icon(time)
  local speed = 1
  local amp = 0.1
  love.graphics.setColor(colorScheme.background)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  love.graphics.rotate(0.5 * math.sin(time)^5)
  love.graphics.scale((0.75 - amp) + amp * math.sin(time * math.pi * speed * 2)^6)
  color = colors[1 + (math.floor(time * speed) % #colors)]
  love.graphics.setColor(colorScheme[color][2])
  love.graphics.polygon('fill', roundhex)
  love.graphics.setColor(colorScheme[color][1])
  love.graphics.translate(0, -0.1)
  love.graphics.scale(0.98)
  love.graphics.polygon('fill', roundhex)
end

return patch