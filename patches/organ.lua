local patch = { name = 'organ' }

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

function patch.icon(time)
  local width = 0.5
  local off = math.sin(time) * 0.05
  for x=-1, 1, width do
    -- pipe
    love.graphics.setColor(0.95, 0.9, 0.3)
    love.graphics.rectangle('fill', x, -1, width*0.9, 2)
    -- shading
    love.graphics.setColor(1, 1, 0.5)
    love.graphics.rectangle('fill', x + width * 0.05, -1, width * 0.3 + off, 2)
    -- lip
    love.graphics.setColor(0.3, 0.3, 0.2)
    love.graphics.ellipse('fill', x + width * 0.5, 0.5 + math.sin(x + time)*0.05, width * 0.35, width * 0.15)
  end
end

return patch