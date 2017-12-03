local patch = {}

local l = require('lume')
local sampler = require('sampler')
local hexpad = require('hexpad')

local keyboard
local tone

local scaling = 0.7 -- cell size can be smaller as we never press neighour notes
                    -- and we need horizontal room to be able to play whole interbal

function patch.load()
  keyboard = hexpad.new(4, 8)
  slide = sampler.new({
    {path='patches/thumb/bass_synthetic_053.ogg', transpose=7},
    looped = true,
    envelope = { attack = 0.20, decay = 0.50, sustain = 0.85, release = 0.35 },
  })
end

local portamento = {} -- store previus notes info for portamento effect
local pTime = 0.5
local speed = 8
local minDur = 0.1

function patch.process(s)
  love.graphics.push()
  love.graphics.scale(scaling)
  love.graphics.rotate(-math.pi / 2)
  keyboard:interpret(s)
  for id, touch in pairs(s.touches) do

    if touch.noteRetrigger then
      if not portamento[id] then
        -- newly pressed note, play as is
        portamento[id] = { from    = touch.note,
                           current = touch.note,
                           to      = touch.note }
      end
    end
    if touch.duration < minDur then
      touch.note = portamento[id].to
    elseif touch.duration - s.dt < minDur then
        -- slide for current note to new one
        portamento[id] = { from    = portamento[id].to,
                           current = portamento[id].to,
                           to      = touch.note }
    else
      -- calculate actual slide
      touch.note = portamento[id].from +
        (portamento[id].to - portamento[id].from) *
        (1 - math.exp(-(touch.duration - minDur) * speed))
    end

  end

  -- remove untouched notes
  for id, p in pairs(portamento) do
    if not s.touches[id] then
      portamento[id] = nil
    end
  end

  slide:update(s.dt, s.touches)
  love.graphics.pop()
end

function patch.draw(s)
  love.graphics.push()
  love.graphics.scale(scaling)
  love.graphics.rotate(-math.pi / 2)
  keyboard:draw(s)
  love.graphics.pop()
end

function patch.icon(time, s)
  love.graphics.setColor(0.4, 0.4, 0.8)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- correct orientation
  love.graphics.setColor(0.2, 0.2, 0.1)
  love.graphics.rectangle('fill', -0.5, -0.3, 1.0, 0.6)
  -- current orientation
  love.graphics.rotate(-s.tilt.lp[2] * math.pi / 2 + math.pi / 2)

  love.graphics.setColor(0.2, s.tilt.lp[2] * 0.6, 0.1)
  love.graphics.rectangle('fill', -0.5, -0.3, 1.0, 0.6)
end

return patch
