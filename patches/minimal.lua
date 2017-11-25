local patch = { name = 'minimal' }

local l = require('lume')
local sampler = require('sampler')
local hexpad = require('hexpad')

local keyboard
local loop

function patch.load()
  keyboard = hexpad.new()

  loop = sampler.new({
    path='samples/briteLoop.wav', looped = true,
    envelope = { attack = 0.20, decay = 0.50, sustain = 0.85, release = 0.35 },
  })
end

function patch.process(s)
  keyboard:interpret(s)
  loop:update(s.dt, s.touches)
end

function patch.draw(s)
  keyboard:draw(s)
end

function patch.icon(time)
  local shade = 0.5 + 0.2 * math.cos(time)
  love.graphics.setColor(shade, shade, shade)
  love.graphics.circle('fill', 0, 0, 1)
end

return patch