local patch = {}

local sampler = require('sampler')

local samplerLoop, samplerStart

function patch.load()
  samplerLoop = sampler.new({
    path='samples/stringsStart.wav',
    looped = false,
  })

  samplerStart = sampler.new({
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
  samplerLoop:update(stream.dt, stream.touches)
  samplerStart:update(stream.dt, stream.touches)
  return stream
end

return patch