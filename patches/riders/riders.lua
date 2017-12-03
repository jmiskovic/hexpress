local patch = { name = 'riders' }

local l = require('lume')
local efx = require('efx')

local sampler = require('sampler')
local hexpad = require('hexpad')

local keyboard
local rhodes, rain

local filter = {
  volume   = 1.0,
  type     = 'lowpass',
  highgain = 0.5,
}

function patch.load()
  --rain = sampler.new({path='riders/rain.ogg', looped = true, synthCount=1})
  --local source = rain.synths[1].source
  --source:play()
  --source:setPosition(0.2, 0.5, 0)
  --source:seek(math.random() * source:getDuration())
  --source:setVolume(0)

  efx.addEffect(efx.tremolo)
  efx.reverb.decaytime = 2.0
  efx.tremolo.frequency = 4

  keyboard = hexpad.new()

  rhodes = sampler.new({
    {path='patches/riders/A_029__F1_1.ogg', note =-19, velocity = 0.9},
    {path='patches/riders/A_029__F1_2.ogg', note =-19, velocity = 0.7},
    {path='patches/riders/A_029__F1_3.ogg', note =-19, velocity = 0.5},
    {path='patches/riders/A_029__F1_4.ogg', note =-19, velocity = 0.3},
    {path='patches/riders/A_029__F1_5.ogg', note =-19, velocity = 0.1},
    {path='patches/riders/A_040__E2_1.ogg', note = -8, velocity = 0.9},
    {path='patches/riders/A_040__E2_2.ogg', note = -8, velocity = 0.7},
    {path='patches/riders/A_040__E2_3.ogg', note = -8, velocity = 0.5},
    {path='patches/riders/A_040__E2_4.ogg', note = -8, velocity = 0.3},
    {path='patches/riders/A_040__E2_5.ogg', note = -8, velocity = 0.1},
    {path='patches/riders/A_050__D3_1.ogg', note =  2, velocity = 0.9},
    {path='patches/riders/A_050__D3_2.ogg', note =  2, velocity = 0.7},
    {path='patches/riders/A_050__D3_3.ogg', note =  2, velocity = 0.5},
    {path='patches/riders/A_050__D3_4.ogg', note =  2, velocity = 0.3},
    {path='patches/riders/A_050__D3_5.ogg', note =  2, velocity = 0.1},
    {path='patches/riders/A_062__D4_1.ogg', note = 14, velocity = 0.9},
    {path='patches/riders/A_062__D4_2.ogg', note = 14, velocity = 0.7},
    {path='patches/riders/A_062__D4_3.ogg', note = 14, velocity = 0.5},
    {path='patches/riders/A_062__D4_4.ogg', note = 14, velocity = 0.3},
    {path='patches/riders/A_062__D4_5.ogg', note = 14, velocity = 0.1},
    synthCount = 3,
--    {path='riders/A_076__E5_2.ogg', transpose =-28, velocity = 0.7},
    envelope = { attack = 0, decay = 0, sustain = 1, release = 0.15 },
    })

end

function patch.process(s)
  keyboard:interpret(s)
  if not s.pressureSupport then
    for _,touch in pairs(s.touches) do
      touch.pressure      = l.remap(s.tilt[2], 0.2, 0.7, 0.1, 1, 'clamp')
      rhodes.masterVolume = l.remap(s.tilt[2], 0.0, 0.7, 0.1, 1, 'clamp')
    end
  end
  efx.tremolo.frequency = l.remap(s.tilt.lp[1], -0.3, 0.3, 0, 15, 'clamp')
  filter.highgain = l.remap(s.tilt.lp[2], 0, 0.7, 0, 1, 'clamp')
  rhodes:update(s.dt, s.touches)
  --local source = rain.synths[1].source
  --source:setVolume(l.remap(s.time, 0, 5, 0, 0.017, 'clamp'))
  --source:setFilter(filter)
end

function patch.draw(s)
  keyboard:draw(s)
end

local colorScheme = {
  flash = {1,1,1},
  night = {0.07, 0.12, 0.16},
}

function patch.icon(time)
  -- lightning
  local color = math.random() < 0.99 and colorScheme.night or colorScheme.flash
  love.graphics.setColor(color)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- rain
  local shade = 0.2 + 0.2 * math.random()
  love.graphics.setColor(shade, shade, shade)
  love.graphics.setLineWidth(0.02)
  local x1 = math.random() * 2 - 1
  local y1 = -8 * math.random()
  local x2 = x1 + math.random() * 0.3 + 0.2
  local y2 =  8 * math.random()
  love.graphics.line(x1, y1, x2, y2)
end

return patch
