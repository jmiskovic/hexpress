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

return patch