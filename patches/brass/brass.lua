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

function patch.load()
  patch.keyboard = hexpad.new()

  patch.trombone  = sampler.new({
    {path='patches/brass/Trombone_Sustain_F1_v5_1.ogg',  note= -7},
    {path='patches/brass/Trombone_Sustain_A1_v5_1.ogg',  note= -3},
    {path='patches/brass/Trombone_Sustain_C2_v5_1.ogg',  note=  0},
    {path='patches/brass/Trombone_Sustain_D#2_v5_1.ogg', note=  3},
    {path='patches/brass/Trombone_Sustain_G2_v5_1.ogg',  note=  7},
    {path='patches/brass/Trombone_Sustain_A#2_v5_1.ogg', note= 10},
    {path='patches/brass/Trombone_Sustain_D3_v5_1.ogg',  note= 14},
    {path='patches/brass/Trombone_Sustain_F3_v5_1.ogg',  note= 17},
    looped=true,
    })

  patch.trombuzz = sampler.new({
    {path='patches/brass/Trombone_Buzz_F1_v2_1.ogg', note= notes.toIndex['F3']},
    {path='patches/brass/Trombone_Buzz_A1_v2_1.ogg', note= notes.toIndex['A3']},
    {path='patches/brass/Trombone_Buzz_C2_v2_1.ogg', note= notes.toIndex['C4']},
    {path='patches/brass/Trombone_Buzz_D#2_v2_1.ogg',note= notes.toIndex['D#4']},
    {path='patches/brass/Trombone_Buzz_G2_v2_1.ogg', note= notes.toIndex['G4']},
    {path='patches/brass/Trombone_Buzz_A#2_v2_1.ogg',note= notes.toIndex['A#4']},
    {path='patches/brass/Trombone_Buzz_D#3_v2_1.ogg',note= notes.toIndex['D#5']},
    envelope = { attack = 0.4, decay = 0.3, sustain = 0.8, release = 0.1 },
    looped=true,
    })

  patch.ensemble = sampler.new({
    {path='patches/brass/trumpet004.ogg',  note=  4},
    {path='patches/brass/trumpet005.ogg',  note=  7},
    {path='patches/brass/trumpet006.ogg',  note= 12},
    {path='patches/brass/trumpet007.ogg',  note= 16},
    {path='patches/brass/trumpet008.ogg',  note= 19},
    {path='patches/brass/trumpet009.ogg',  note= 24},
    {path='patches/brass/trumpet010.ogg',  note= 28},
    {path='patches/brass/trumpet011.ogg',  note= 31},
    transpose = 12,
  })
  love.graphics.setBackgroundColor(colorScheme.background)

  function patch.keyboard:drawCell(q, r, s, touch)
    local delta = 0
    if touch and touch.volume then
      delta = touch.volume
    end
    local note = patch.keyboard:toNoteIndex(q, r)
    love.graphics.translate(0, delta/10)
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
  patch.keyboard:interpret(s)
  -- crossfade between instruments
  patch.ensemble.masterVolume = l.remap(s.tilt.lp[1],-.2,  .1, 0, 1, 'clamp')
  patch.trombone.masterVolume = l.remap(s.tilt.lp[1], .1, -.1, 0, 1, 'clamp')
  patch.trombuzz.masterVolume = l.remap(s.tilt.lp[2], .2, -.1, 0, 1, 'clamp')
  patch.trombone:processTouches(s.dt, s.touches)
  patch.trombuzz:processTouches(s.dt, s.touches)
  patch.ensemble:processTouches(s.dt, s.touches)
  return s
end

function patch.draw(s)
  patch.keyboard:draw(s)
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