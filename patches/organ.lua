local patch = {}

local sampler = require('sampler')

local samplerLoop, samplerStart

function patch.load()
samplerLoop = sampler.new({
  path='samples/briteLoop.wav',
  transpose = 0,
  sourceCount = 5,
  looped = true,
  })

 samplerStart = sampler.new({
   path='samples/briteLoop.wav',
   transpose = 7,
   sourceCount = 5,
   looped = false,
   })
end


function patch.process(stream)
  stream = samplerLoop:process(stream)
  stream = samplerStart:process(stream)
  return stream
end

return patch