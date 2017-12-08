local patch = {}

local sampler = require('sampler')
local hexgrid = require('hexgrid')
local hexpad = require('hexpad')
local efx = require('efx')
local l = require('lume')

local colorScheme = {
  brass = {l.rgba(0xccad00ff)},
  steel = {l.rgba(0xc6b3b5ff)},
  shade = {l.rgba(0xffffff90)},
  background = {l.rgba(0xcf9f6bff)},
}

local keyboard
local tuba, trombone

function patch.load()
  keyboard = hexpad.new()
  tuba = sampler.new({
    {path='patches/brass/Tuba3_sus_A#0_v3_rr1_Mid.ogg', note=-14},
    {path='patches/brass/Tuba3_sus_D#1_v3_rr1_Mid.ogg', note= -9},
    {path='patches/brass/Tuba3_sus_F1_v3_rr1_Mid.ogg',  note= -7},
    {path='patches/brass/Tuba3_sus_A#1_v3_rr1_Mid.ogg', note= -2},
    {path='patches/brass/Tuba3_sus_A#2_v3_rr1_Mid.ogg', note= 10},
    {path='patches/brass/Tuba3_sus_D2_v3_rr1_Mid.ogg',  note=  2},
  })

  trombone  = sampler.new({
    {path='patches/brass/Trombone_Sustain_A1_v5_1.ogg',  note= -3},
    {path='patches/brass/Trombone_Sustain_A2_v5_1.ogg',  note= 9},
    {path='patches/brass/Trombone_Sustain_A#1_v5_1.ogg', note= -2},
    {path='patches/brass/Trombone_Sustain_A#2_v5_1.ogg', note= 10},
    {path='patches/brass/Trombone_Sustain_C2_v5_1.ogg',  note= 0},
    {path='patches/brass/Trombone_Sustain_C3_v5_1.ogg',  note= 12},
    {path='patches/brass/Trombone_Sustain_D2_v5_1.ogg',  note= 2},
    {path='patches/brass/Trombone_Sustain_D3_v5_1.ogg',  note= 14},
    {path='patches/brass/Trombone_Sustain_D#2_v5_1.ogg', note= 3},
    {path='patches/brass/Trombone_Sustain_D#3_v5_1.ogg', note= 15},
    {path='patches/brass/Trombone_Sustain_F1_v5_1.ogg',  note= -7},
    {path='patches/brass/Trombone_Sustain_F2_v5_1.ogg',  note= 5},
    {path='patches/brass/Trombone_Sustain_F3_v5_1.ogg',  note= 17},
    {path='patches/brass/Trombone_Sustain_G1_v5_1.ogg',  note= -5},
    {path='patches/brass/Trombone_Sustain_G2_v5_1.ogg',  note= 7},
    {path='patches/brass/Trombone_Sustain_G3_v5_1.ogg',  note= 19},
  })
  efx.reverb.decaytime = 1
  love.graphics.setBackgroundColor(colorScheme.background)

  function keyboard:drawCell(q, r, s, touch)
    local delta = 0
    if touch and touch.volume then
      delta = touch.volume
    end
    love.graphics.translate(0, delta/5)
    love.graphics.scale(0.85)
    love.graphics.setColor(colorScheme.steel)
    love.graphics.circle('fill', 0, 0, 1)
    love.graphics.setColor(colorScheme.shade)
    love.graphics.translate(0, -0.15)
    love.graphics.circle('fill', 0, 0, 0.8)
  end

end

function patch.process(s)
  keyboard:interpret(s)
  -- crossfade between instruments
  tuba.masterVolume   = l.remap(s.tilt.lp[1], -0.2, 0.3, 1, 0.2, 'clamp')
  trombone.masterVolume = l.remap(s.tilt.lp[1], -0.1, 0.4, 0.2, 1, 'clamp')
  for _,touch in pairs(s.touches) do
    if touch.note then
      touch.note = l.remap(s.tilt.lp[2], -0.2, -1, touch.note, touch.note / 2, 'clamp')
    end
  end
  tuba:update(s.dt, s.touches)
  trombone:update(s.dt, s.touches)
  return s
end

function patch.draw(s)
  keyboard:draw(s)
end

function patch.icon(time)
  love.graphics.setColor(colorScheme.shade)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  local valve_min = 0.1
  local valve_max = 0.35
  local ds = math.cos(time) * 0.03 -- shading offset
  for i=-1,1 do
    local x = i * 0.8
    local y = -valve_max * math.sin(time + i * math.pi/3)^4
    -- casings
    love.graphics.setColor(colorScheme.brass)
    love.graphics.rectangle('fill', x - 0.35, valve_min, 0.7, 1)
    love.graphics.setColor(colorScheme.shade)
    love.graphics.rectangle('fill', x - 0.2 + ds, valve_min, 0.1, 1)
    love.graphics.setColor(colorScheme.brass)
    love.graphics.ellipse('fill', x, valve_min, 0.35, 0.1)
    -- pistons
    love.graphics.setColor(colorScheme.steel)
    love.graphics.rectangle('fill', x - 0.1,  valve_min, 0.2,  -valve_min + y)
    love.graphics.setColor(colorScheme.shade)
    love.graphics.rectangle('fill', x - 0.05 + ds, valve_min, 0.05, -valve_min + y)
    -- valves
    love.graphics.setColor(colorScheme.steel)
    love.graphics.ellipse('fill', x, y, 0.32, 0.1)
    love.graphics.setColor(colorScheme.shade)
    love.graphics.ellipse('fill', x, y - 0.05, 0.28, 0.05)
  end
  -- lead pipe
  love.graphics.setColor(colorScheme.brass)
  love.graphics.rectangle('fill', -2, 0.5, 4, 0.6)
  love.graphics.setColor(colorScheme.shade)
  love.graphics.rectangle('fill', -2, 0.58, 4, 0.05 + ds)
end

return patch