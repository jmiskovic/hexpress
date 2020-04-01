local patch = {}
patch.__index = patch

local sampler = require('sampler')
local freeform = require('freeform')
local efx = require('efx')
local l = require('lume')

local colorScheme = {
           -- pad color             frame color
  green    = {{l.rgba(0x2a6222ff)}, {l.rgba(0x559644ff)}},
  red      = {{l.rgba(0x91251cff)}, {l.rgba(0xd83a2cff)}},
  orange   = {{l.rgba(0xa84c0cff)}, {l.rgba(0xf47e35ff)}},
  blue     = {{l.rgba(0x264452ff)}, {l.rgba(0x53a691ff)}},
  gray    = {{l.rgba(0x825e4cff)}, {l.rgba(0xc0957cff)}},
  background = {l.rgba(0x000000ff)},
}

local colors = {'red', 'green', 'orange', 'blue', 'gray'}

function patch.load()
  local self = setmetatable({}, patch)
  local triggers = { -- elements are listed in draw order (lowest to highest)
    -- each group is single color, and with elements: kick, snare, hihat, crash
    {path=
     'patches/electrobeats/JoelVenomLayerKick.ogg',
     color='gray',    x=-1.404, y= 0.765, r= 0.24},
    {path=
     'patches/electrobeats/OS_DSND_Kick4.ogg',
     color='gray',    x=-0.828, y= 0.689, r= 0.30},
    {path=
     'patches/electrobeats/KickRoleModelz.ogg',
     color='gray',    x=-0.039, y= 0.676, r= 0.31},
    {path=
     'patches/electrobeats/clapwhoops-wrldview.ogg',
     color='gray',    x= 0.696, y= 0.665, r= 0.33},


    {path=
     'patches/electrobeats/DrillSnarev26.ogg',
     color='orange',    x=-1.418, y= 0.222, r= 0.33},
    {path=
     'patches/electrobeats/Teck-percnineteen85.ogg',
     color='orange',    x=-0.935, y=-0.109, r= 0.26},
    {path=
     'patches/electrobeats/PercConga.ogg',
     color='orange',    x=-0.485, y= 0.235, r= 0.30},
    {path=
     'patches/electrobeats/M-TRSnareDark.ogg',
     color='orange',    x= 0.274, y= 0.243, r= 0.19},
    {path=
     'patches/electrobeats/TIGHTMSNARE2.ogg',
     color='orange',    x= 0.879, y= 0.064, r= 0.28},
    {path=
     'patches/electrobeats/revsnare.ogg',
     color='orange',    x= 1.396, y= 0.526, r= 0.40},


    {path=
     'patches/electrobeats/KENNYBEATSCRASH7.ogg',
     color='green',    x=-1.382, y=-0.343, r= 0.25},
    {path=
     'patches/electrobeats/OpenHihat8.ogg',
     color='green',    x=-0.120, y=-0.141, r= 0.26},
    {path=
     'patches/electrobeats/Teck-hihat10.ogg',
     color='green',    x= 0.417, y=-0.324, r= 0.33},
    {path=
     'patches/electrobeats/Teck-openhihatjuice.ogg',
     color='green',    x= 1.391, y=-0.272, r= 0.33},

    {path=
     'patches/electrobeats/MBNarcaticsHit.ogg',
     color='blue',    x=-0.551, y=-0.337, r= 0.15},
    {path=
     'patches/electrobeats/venus-synth.ogg',
     color='blue',    x=-0.885, y=-0.561, r= 0.19},
    {path=
     'patches/electrobeats/polish-synth.ogg',
     color='blue',    x=-1.233, y=-0.776, r= 0.21},
    {path=
     'patches/electrobeats/elastic-synth.ogg',
     color='blue',    x=-0.271, y=-0.535, r= 0.18},
    {path=
     'patches/electrobeats/delayed-synth.ogg',
     color='blue',    x= 0.061, y=-0.756, r= 0.22},

    {path=
     'patches/electrobeats/PercOGKush2.ogg',
     color='red',    x=-0.557, y=-0.737, r= 0.18},
    {path=
     'patches/electrobeats/dish-accent.ogg',
     color='red',    x= 0.481, y=-0.811, r= 0.17},
    {path=
     'patches/electrobeats/NM-LiveFX3.ogg',
     color='red',    x= 0.818, y=-0.611, r= 0.19},
    {path=
     'patches/electrobeats/MBTransFX1.ogg',
     color='red',    x= 1.169, y=-0.776, r= 0.11},

    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.2 },
  }
  self.efx = efx.load()
  for i, element in ipairs(triggers) do
    element.type = 'hex'
  end
  self.layout = freeform.new(triggers)
  self.sampler = sampler.new(triggers)
  love.graphics.setBackgroundColor(colorScheme.background)
  return self
end


function patch:process(s)
  self.layout:interpret(s)
  self.efx.reverb.decaytime = l.remap(s.tilt.lp[1], 0.1, -0.5, 0.5, 4)
  self.efx:process()
  self.sampler:processTouches(s.dt, s.touches, self.efx)
  return s
end


function patch:draw(s)
  self.layout:draw(s)
end


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