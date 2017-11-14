local patch = {}

local sampler = require('sampler')

local samplerLoop, samplerStart

function patch.load()
  punch = sampler.new({
    path='samples/strings.wav',
    looped = false,
  })

  loop = sampler.new({
    path='samples/stringsLoop.wav',
    looped = true,
    envelope = {
      attack  = 1.00,
      decay   = 0.20,
      sustain = 0.95,
      release = 0.35,
    },
  })
end

function patch.process(stream)
  punch:update(stream.dt, stream.touches)
  loop:update(stream.dt, stream.touches)
  return stream
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
  love.graphics.setColor(0.6, 0.6, 0.6)
  love.graphics.line(-1, tilt + gap, 1, - tilt + gap)
  love.graphics.setColor(0.3, 0.1, 0)
  love.graphics.line(-1, tilt, 1, -tilt)
end

return patch