local patch = {}
local l = require("lume")
local sampler = require('sampler')
local hexpad = require('hexpad')
local hexgrid = require('hexgrid')

local keyboard
local cello, doublebass
local colorScheme = {
  wood    = {l.color('#8c3c00')},
  neck    = {l.color('#302400')},
  strings = {l.color('#988c75')},
  stick   = {l.color('#a39782')},
  hair    = {l.color('#5e2400')},
}

function patch.load()
  keyboard = hexpad.new()

  cello = sampler.new({
    {path='patches/strings/susvib_A2_v3.ogg', note=  9},
    {path='patches/strings/susvib_B1_v3.ogg', note= -1},
    {path='patches/strings/susvib_C1_v3.ogg', note=-12},
    {path='patches/strings/susvib_C3_v3.ogg', note= 12},
    {path='patches/strings/susvib_D2_v3.ogg', note=  2},
    {path='patches/strings/susvib_D4_v3.ogg', note= 26},
    {path='patches/strings/susvib_E1_v3.ogg', note= -8},
    {path='patches/strings/susvib_E3_v3.ogg', note= 16},
    {path='patches/strings/susvib_F2_v3.ogg', note=  5},
    {path='patches/strings/susvib_F4_v3.ogg', note= 29},
    {path='patches/strings/susvib_G1_v3.ogg', note= -5},
    {path='patches/strings/susvib_G3_v3.ogg', note= 19},
    looped = true,
    envelope = {attack = 0.2, decay = 0.1, sustain = 0.8, release = 0.6},
  })

  tremolo = sampler.new({
    {path='patches/strings/trem_A2_v2.ogg', note =  -3},
    {path='patches/strings/trem_B2_v2.ogg', note =  -1},
    {path='patches/strings/trem_B3_v2.ogg', note =  11},
    {path='patches/strings/trem_C1_v2.ogg', note = -24},
    {path='patches/strings/trem_C3_v2.ogg', note =   0},
    {path='patches/strings/trem_D2_v2.ogg', note = -10},
    {path='patches/strings/trem_D4_v2.ogg', note =  14},
    {path='patches/strings/trem_E1_v2.ogg', note = -20},
    {path='patches/strings/trem_E3_v2.ogg', note =   4},
    {path='patches/strings/trem_F2_v2.ogg', note =  -7},
    {path='patches/strings/trem_F4_v2.ogg', note =  17},
    {path='patches/strings/trem_G1_v2.ogg', note = -17},
    {path='patches/strings/trem_G3_v2.ogg', note =   7},
    looped = false,
    envelope = {attack = 0.0, decay = 0.1, sustain = 1.0, release = 0.5},
  })

  love.graphics.setBackgroundColor(colorScheme.neck)
end

function patch.process(s)
  keyboard:interpret(s)
  -- fade in from bellow
  cello.envelope.attack   = l.remap(s.tilt.lp[2], -0.9, -0.1, 10, 0.2, 'clamp')
  tremolo.envelope.attack = l.remap(s.tilt.lp[2], -0.9, -0.1, 10, 0.2, 'clamp')
  -- crossfade between instruments
  cello.masterVolume   = l.remap(s.tilt.lp[1], -0.2, 0.3, 1, 0.2, 'clamp')
  tremolo.masterVolume = l.remap(s.tilt.lp[1], -0.1, 0.4, 0.2, 1, 'clamp')
  cello:update(s.dt, s.touches)
  tremolo:update(s.dt, s.touches)
  return s
end

function patch.draw(s)
  touched = {{}, {}, {}}
  -- mark touched 'strings' across three axes
  for k,touch in pairs(s.touches) do
    if touch.qr then
      local tx, ty, tz = hexgrid.axialToCube(unpack(touch.qr))
      touched[1][tx] = math.max(touch.volume or 0, touched[1][tx] or 0)
      touched[2][ty] = math.max(touch.volume or 0, touched[2][ty] or 0)
      touched[3][tz] = math.max(touch.volume or 0, touched[3][tz] or 0)
    end
  end
  -- draw strings across 3 axes, vibrate strings that intersect touches
  love.graphics.scale(keyboard.scaling)
  local t1, t2, x, y, z, sx, sy, ex, ey
  local r = keyboard.radius
  for i = -r, r do -- covering range on single axis
    t1 = {
      i,
      math.min( r, r - i),
      math.max(-r, -(r + i)), --tile at the edge of radius
      }   --tile at the other edge of radius
    t2 = {
      i,
      math.max(-r, -(r + i)),
      math.min( r, r - i),
      }
    -- phew...
    for a=1, 3 do -- iterating over 3 axes in cube coordinates
      colorScheme.strings[4] = 0.4 + 0.2 * a
      love.graphics.setColor(colorScheme.strings)
      x, y, z = t1[(a - 1) % 3 + 1], t1[(a + 0) % 3 + 1], t1[(a + 1) % 3 + 1]
      sx, sy = hexgrid.hexToPixel(hexgrid.cubeToAxial(x, y, z))
      x, y, z = t2[(a - 1) % 3 + 1], t2[(a + 0) % 3 + 1], t2[(a + 1) % 3 + 1]
      ex, ey = hexgrid.hexToPixel(hexgrid.cubeToAxial(x, y, z))
      love.graphics.setLineWidth(0.06)
      if touched[a][i] then
        love.graphics.push()
        love.graphics.translate(0.03 * math.sin(s.time * 50 + a), 0.03 * math.cos(s.time * 50 + a))
        love.graphics.line(sx, -sy, ex, -ey)
        love.graphics.pop()
      else
        love.graphics.line(sx, -sy, ex, -ey)
      end
    end
  end
end

function patch.icon(time)
  love.graphics.rotate(0.04)
  -- wood body
  love.graphics.setColor(colorScheme.wood)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- neck
  love.graphics.setColor(colorScheme.neck)
  love.graphics.rectangle('fill', -0.5, -1, 1, 2)
  -- strings
  love.graphics.setLineWidth(0.05)
  love.graphics.setColor(colorScheme.strings)
  love.graphics.line(math.sin(50*time) * 0.02,   1,  0,   -1) -- this one vibrates
  love.graphics.line(-0.2, 1, -0.2, -1)
  love.graphics.line( 0.2, 1,  0.2, -1)
  -- bow
  local tilt = -0.2 + math.sin(time) * 0.1
  local gap = 0.15
  local span = 1.2
  love.graphics.setColor(colorScheme.stick)
  love.graphics.setLineWidth(0.08)
  love.graphics.line(-span, tilt + gap, span, - tilt + gap)
  love.graphics.setColor(colorScheme.hair)
  love.graphics.setLineWidth(0.14)
  love.graphics.line(-span, tilt, span, -tilt)
end

return patch