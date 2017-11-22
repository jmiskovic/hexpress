local patch = {}
local l = require("lume")
local sampler = require('sampler')
local hexpad = require('hexpad')

local keyboard
local cello, doublebass

function patch.load()
  keyboard = hexpad.new(4)

  cello = sampler.new({
    path='samples/cello_C2_mf_g.wav', looped = true,
    envelope = {attack= 0.3, decay = 0.10, sustain = 1, release = 0.35},
  })

  doublebass = sampler.new({
    path='samples/doublebass_pluck_c2_vl3_rr3.wav', looped = false,
    envelope = {attack= 0, decay = 0.20, sustain = 1, release = 0.35},
  })
end

function patch.process(s)
  keyboard:interpret(s)
  -- crossfade between instruments
  doublebass.masterVolume = l.remap(s.tilt[2], 0.2, 0.3, 0, 1, 'clamp')
  cello.masterVolume      = l.remap(s.tilt[2], 0.4, 0.3, 0, 1, 'clamp')
  track('tilt %1.2f', s.tilt[2])
  track('volume %1.2f', cello.masterVolume)
  cello:update(s.dt, s.touches)
  doublebass:update(s.dt, s.touches)
  return s
end

function patch.draw(s)
  keyboard:draw(s)
end

function patch.icon(time)
  -- wood body
  love.graphics.setColor(0.5, 0.2, 0)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- neck
  love.graphics.setColor(0.1, 0.1, 0)
  love.graphics.rectangle('fill', -0.5, -1, 1, 2)
  -- strings
  love.graphics.setLineWidth(0.05)
  love.graphics.setColor(0.6, 0.6, 0.6)
  love.graphics.line(math.sin(50*time) * 0.02,   1,  0,   -1) -- this one vibrates
  love.graphics.line(-0.2, 1, -0.2, -1)
  love.graphics.line( 0.2, 1,  0.2, -1)
  -- bow
  love.graphics.setLineWidth(0.1)
  local tilt = -0.2 + math.sin(time) * 0.1
  local gap = 0.15
  local span = 1.2
  love.graphics.setColor(0.6, 0.6, 0.6)
  love.graphics.line(-span, tilt + gap, span, - tilt + gap)
  love.graphics.setColor(0.3, 0.1, 0)
  love.graphics.line(-span, tilt, span, -tilt)
end

return patch