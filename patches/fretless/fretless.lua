local patch = {}

local l = require('lume')
local efx = require('efx')
local notes = require('notes')
local fretboard = require('fretboard')
local sampler = require('sampler')

local colorScheme = {
  dot    = {l.rgba(0xe13018ff)},
  body   = {l.rgba(0x3c4e5dff)},
  pickup = {l.rgba(0x21241eff)},
  string = {l.rgba(0x757472ff)},
  light  = {l.rgba(0xffffff70)},
}

function patch.load()
  local tapePath = 'patches/broom/seventies-pop-funk-groove.ogg'
  patch.keyboard = fretboard.new(false, {-47, -42, -37, -32, -27, -22, -17, -12})
  patch.keyboard.fretWidth = 0.4

  patch.tone = sampler.new({
    {path='patches/fretless/C1.ogg',  note = notes.toIndex['C1']},
    {path='patches/fretless/D#1.ogg', note = notes.toIndex['D#1']},
    {path='patches/fretless/F#1.ogg', note = notes.toIndex['F#1']},
    {path='patches/fretless/A1.ogg',  note = notes.toIndex['A1']},
    {path='patches/fretless/C2.ogg',  note = notes.toIndex['C2']},
    {path='patches/fretless/D#2.ogg', note = notes.toIndex['D#2']},
    {path='patches/fretless/F#2.ogg', note = notes.toIndex['F#2']},
    {path='patches/fretless/A2.ogg',  note = notes.toIndex['A2']},
    {path='patches/fretless/C3.ogg',  note = notes.toIndex['C3']},
    {path='patches/fretless/D#3.ogg', note = notes.toIndex['D#3']},
    {path='patches/fretless/F#3.ogg', note = notes.toIndex['F#3']},
    {path='patches/fretless/A3.ogg',  note = notes.toIndex['A3']},
    {path='patches/fretless/C4.ogg',  note = notes.toIndex['C4']},
    {path='patches/fretless/D#4.ogg', note = notes.toIndex['D#4']},
    {path='patches/fretless/F#4.ogg', note = notes.toIndex['F#4']},
    {path='patches/fretless/A4.ogg',  note = notes.toIndex['A4']},
    envelope = {attack = 0.0, decay = 0, sustain = 1, release = 0.05 },
    transpose= 0,
    })
end

function patch.process(s)
  patch.keyboard:interpret(s)
  efx.reverb.decaytime = l.remap(s.tilt.lp[2], -.1, 2, 0.5, 2)
  patch.tone:processTouches(s.dt, s.touches)
end

function patch.draw(s)
  patch.keyboard:draw(s)
  -- dots
  love.graphics.setColor(colorScheme.dot)
  for _, cNote in ipairs(patch.keyboard.cNotePositions) do
    love.graphics.circle('fill', -0.2 + cNote[1], cNote[2] - 0.08, 0.05)
  end
end

function patch.icon(time, s)
  -- body
  love.graphics.setColor(colorScheme.body)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  -- pickup
  love.graphics.setColor(colorScheme.pickup)
  love.graphics.rectangle('fill', -0.5, -0.9, 0.7, 1.8)
  love.graphics.setColor(colorScheme.light)
  love.graphics.circle('fill', -0.15, -0.8, 0.05)
  love.graphics.circle('fill', -0.15,  0.8, 0.05)
  -- strings
  love.graphics.setLineWidth(0.08)
  love.graphics.setColor(colorScheme.string)
  love.graphics.line(-1,-0.6,  1,-0.6)
  love.graphics.line(-1,-0.2, 1, -0.2 + math.sin(50*time) * 0.02)
  love.graphics.line(-1, 0.2, 1,  0.2)
  love.graphics.line(-1, 0.6,  1, 0.6)
  love.graphics.setLineWidth(0.04)
  love.graphics.setColor(colorScheme.light)
  love.graphics.line(-1,-0.6, 1,-0.6)
  love.graphics.line(-1,-0.2, 1,-0.2 + math.sin(50*time) * 0.02)
  love.graphics.line(-1, 0.2, 1, 0.2)
  love.graphics.line(-1, 0.6, 1, 0.6)
end


return patch