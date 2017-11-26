local patch = {}

local l = require('lume')
local sampler = require('sampler')
local hexpad = require('hexpad')

local keyboard
local tone

function patch.load()
  keyboard = hexpad.new()
  tone = sampler.new({
    {path='bones/nsynth_bass_synthetic_1.wav', velocity=0.1},
    {path='bones/nsynth_bass_synthetic_3.wav', velocity=0.5},
    {path='bones/nsynth_bass_synthetic_5.wav', velocity=0.9},
    envelope = { attack = 0.20, decay = 0.50, sustain = 0.85, release = 0.35 },
  })
end

function patch.process(s)
  keyboard:interpret(s)
  tone.masterVolume = l.remap(s.tilt[2], -1, 1, 0, 0.5)
  tone:update(s.dt, s.touches)
end

function patch.draw(s)
  love.graphics.push()
  love.graphics.translate(s.sw / 2, s.sh / 2)
  love.graphics.rotate(-math.pi / 2)
  love.graphics.translate(-s.sw / 2, -s.sw / 2)
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

--[[
  function hexpad.hexToNoteIndex(q, r, noteOffset)
    local intervalNE = -3
    local intervalN  = 4
    return noteOffset + q * intervalNE + (-q - r) * intervalN
  end
]]