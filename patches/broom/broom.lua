local patch = {}
patch.__index = patch

local l = require('lume')
local efx = require('efx')
local notes = require('notes')
local fretboard = require('fretboard')
local sampler = require('sampler')

local colorScheme = {
  dot    = {l.rgba(0xe13018ff)},
  body   = {l.rgba(0xdcd4c5ff)},
  pickup = {l.rgba(0x21241eff)},
  string = {l.rgba(0x757472ff)},
  light  = {l.rgba(0xffffff70)},
}


function patch.load()
  local self = setmetatable({}, patch)
  self.layout = fretboard.new(false, {-29, -24, -19, -14, -9, -4, 1, 6})
  self.layout.fretWidth = 0.4
  self.sampler  = sampler.new({
    {path='patches/broom/acbass_A21.ogg', note = notes.toIndex['A2']},
    {path='patches/broom/acbass_B21.ogg', note = notes.toIndex['B2']},
    {path='patches/broom/acbass_B31.ogg', note = notes.toIndex['B3']},
    {path='patches/broom/acbass_C21.ogg', note = notes.toIndex['C2']},
    {path='patches/broom/acbass_C31.ogg', note = notes.toIndex['C3']},
    {path='patches/broom/acbass_C41.ogg', note = notes.toIndex['C4']},
    {path='patches/broom/acbass_D21.ogg', note = notes.toIndex['D2']},
    {path='patches/broom/acbass_D31.ogg', note = notes.toIndex['D3']},
    {path='patches/broom/acbass_E21.ogg', note = notes.toIndex['E2']},
    {path='patches/broom/acbass_E31.ogg', note = notes.toIndex['E3']},
    {path='patches/broom/acbass_F21.ogg', note = notes.toIndex['F2']},
    {path='patches/broom/acbass_F31.ogg', note = notes.toIndex['F3']},
    {path='patches/broom/acbass_G21.ogg', note = notes.toIndex['G2']},
    {path='patches/broom/acbass_G31.ogg', note = notes.toIndex['G3']},
    envelope = {attack = 0.0, decay = 0, sustain = 1, release = 0.05 }})
  return self
end


function patch:process(s)
  self.layout:interpret(s)
  efx.reverb.decaytime = l.remap(s.tilt.lp[2], 0.7, -0.1, 0.2, 2.0, 'clamp')
  -- sustain pedal
  self.sampler.envelope.release = l.remap(s.tilt[2], .0, -0.2, 0.05, 5, 'clamp')
  self.sampler:processTouches(s.dt, s.touches)
end


function patch:draw(s)
  self.layout:draw(s)
  -- dots
  love.graphics.setColor(colorScheme.dot)
  for _, cNote in ipairs(self.layout.cNotePositions) do
    love.graphics.circle('fill', cNote[1] - self.layout.fretWidth / 2, cNote[2] - 0.08, 0.05)
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