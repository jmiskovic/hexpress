local patch = {}

local sampler = require('sampler')

local samplerLoop, samplerStart

function patch.load()
  samplerLoop = sampler.new({
    path='samples/briteLoop.wav',
    looped = true,
    envelope = {
      attack  = 0.20,
      decay   = 0.50,
      sustain = 0.85,
      release = 0.35,
    },
  })

  samplerStart = sampler.new({
    path='samples/briteLoop.wav',
    transpose = 4,
    looped = false,
    envelope = {
      attack  = 1.40,
      decay   = 0.20,
      sustain = 0.35,
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