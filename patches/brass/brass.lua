local patch = {}

local notes = require('notes')
local sampler = require('sampler')
local hexgrid = require('hexgrid')
local hexpad = require('hexpad')
local efx = require('efx')
local l = require('lume')

local colorScheme = {
  brass      = {l.hsl(0.14, 1.00, 0.40)},
  steel      = {l.hsl(0.98, 0.14, 0.74)},
  steelDark  = {l.hsl(0.98, 0.05, 0.55)},
  background = {l.hsl(0.62, 0.21, 0.52)},
  highlight  = {1, 1, 1, 0.56},
}

local keyboard
local tuba, trombone

function patch.load()
  keyboard = hexpad.new()

  trombone  = sampler.new({
    {path='patches/brass/Trombone_Sustain_F1_v5_1.ogg',  note= -7},
    {path='patches/brass/Trombone_Sustain_A1_v5_1.ogg',  note= -3},
    {path='patches/brass/Trombone_Sustain_C2_v5_1.ogg',  note=  0},
    {path='patches/brass/Trombone_Sustain_D#2_v5_1.ogg', note=  3},
    {path='patches/brass/Trombone_Sustain_G2_v5_1.ogg',  note=  7},
    {path='patches/brass/Trombone_Sustain_A#2_v5_1.ogg', note= 10},
    {path='patches/brass/Trombone_Sustain_D3_v5_1.ogg',  note= 14},
    {path='patches/brass/Trombone_Sustain_F3_v5_1.ogg',  note= 17},
    })

  trumpet = sampler.new({
    {path='/patches/brass/000.061.000.ogg',  note= -8 - 12},
    {path='/patches/brass/000.061.004.ogg',  note=  4 - 12},
    {path='/patches/brass/000.061.005.ogg',  note=  7 - 12},
    {path='/patches/brass/000.061.006.ogg',  note= 12 - 12},
    {path='/patches/brass/000.061.007.ogg',  note= 16 - 12},
    {path='/patches/brass/000.061.008.ogg',  note= 19 - 12},
    {path='/patches/brass/000.061.009.ogg',  note= 24 - 12},
    {path='/patches/brass/000.061.010.ogg',  note= 28 - 12},
    {path='/patches/brass/000.061.011.ogg',  note= 31 - 12},
    --transpose = -3
  })
  love.graphics.setBackgroundColor(colorScheme.background)

  function keyboard:drawCell(q, r, s, touch)
    local delta = 0
    if touch and touch.volume then
      delta = touch.volume
    end
    local note = keyboard:hexToNoteIndex(q, r)
    love.graphics.translate(0, delta/5)
    love.graphics.scale(0.8)
    if note % 12 == 0 then
      love.graphics.setColor(colorScheme.steelDark)
    else
      love.graphics.setColor(colorScheme.steel)
    end
    love.graphics.circle('fill', 0, 0, 1)
    love.graphics.setColor(colorScheme.highlight)
    love.graphics.translate(0, -0.15)
    love.graphics.circle('fill', 0, 0, 0.8)
  end

end

function patch.process(s)
  keyboard:interpret(s)
  -- crossfade between instruments
  trombone.masterVolume = l.remap(s.tilt.lp[1],  0.2, 0.1, 0.2, 1, 'clamp')
  trumpet.masterVolume  = l.remap(s.tilt.lp[1],  0.1, 0.2, 0, 1, 'clamp')
  for _,touch in pairs(s.touches) do
    if touch.note then
      touch.note = l.remap(s.tilt.lp[2], -0.2, -1, touch.note, touch.note / 2, 'clamp')
    end
  end
  -- tuba:update(s.dt, s.touches)
  trombone:update(s.dt, s.touches)
  trumpet:update(s.dt, s.touches)
  return s
end

function patch.draw(s)
  keyboard:draw(s)
end

function patch.icon(time)
  love.graphics.setColor(colorScheme.background)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  local valve_min = 0.1
  local valve_max = 0.25
  local ds = math.cos(time) * 0.03 -- shading offset
  for i=-1,1 do
    local x = i * 0.8
    local y = -valve_max * math.sin(time + i * math.pi/3)^4
    -- casings
    love.graphics.setColor(colorScheme.brass)
    love.graphics.rectangle('fill', x - 0.35, valve_min, 0.7, 1)
    love.graphics.setColor(colorScheme.highlight)
    love.graphics.rectangle('fill', x - 0.2 + ds, valve_min, 0.1, 1)
    love.graphics.setColor(colorScheme.brass)
    love.graphics.ellipse('fill', x, valve_min, 0.35, 0.1)
    -- pistons
    love.graphics.setColor(colorScheme.steel)
    love.graphics.rectangle('fill', x - 0.1,  valve_min, 0.2,  -valve_min + y)
    love.graphics.setColor(colorScheme.highlight)
    love.graphics.rectangle('fill', x - 0.05 + ds, valve_min, 0.05, -valve_min + y)
    -- valves
    love.graphics.setColor(colorScheme.steel)
    love.graphics.ellipse('fill', x, y, 0.32, 0.1)
    love.graphics.setColor(colorScheme.highlight)
    love.graphics.ellipse('fill', x, y - 0.05, 0.28, 0.05)
  end
  -- lead pipe
  love.graphics.setColor(colorScheme.brass)
  love.graphics.rectangle('fill', -2, 0.5, 4, 0.6)
  love.graphics.setColor(colorScheme.highlight)
  love.graphics.rectangle('fill', -2, 0.55, 4, 0.05 + ds)
end

return patch