pad = {}
pad.__index = pad

local synth = require('synth')
local log = require('log')
local min = math.min
local max = math.max
pad.moved = function(self, dx, dy) end -- stub

pad.font_color = {0.13, 0.13, 0.13, 0.5}
note_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
pad.note_offset = 4

-- harmonic note grid from QR coordinate
function pad.hex_to_note(q, r)
    return q*4 + (-q-r)*7 + pad.note_offset
end


--- tonepad ---

function pad.new_tonepad(q, r)
  local self = setmetatable({}, pad)
  self.draw     = pad.draw_tonepad
  self.pressed  = pad.pressed_tonepad
  self.released = pad.released_tonepad
  local note = pad.hex_to_note(q, r)
  self.name = note_names[note % 12 +1]
  self.pitch = math.pow(math.pow(2, 1/12), note)
  self.synth = nil -- index of selected synth, valid while pad is pressed
  return self
end

function pad:draw_tonepad(x, y)
  love.graphics.setFont(self.font)
  local gray = 0.43 - string.len(self.name) * 0.16
  love.graphics.setColor(gray + 0.1, gray + 0.2, gray)
  love.graphics.translate(x, y)
  love.graphics.polygon('fill', self.hexapoly)
  love.graphics.setColor(self.font_color)
  love.graphics.print(self.name, -self.font:getWidth(self.name)/2, -self.font:getHeight()/2)
  love.graphics.origin()
end

function pad:pressed_tonepad()
  self.synth = synth.get_unused()
  self.synth:startNote(self.pitch)
end

function pad:released_tonepad()
  if self.synth then
    self.synth:stopNote()
  end
end

--- grille ---

local grille_image = love.graphics.newImage('grille.png')

function pad.new_grille(q, r)
  self = pad.new_tonepad(q, r)
  self.draw     = pad.draw_grille
  return self
end

function pad:draw_grille(x, y)
  love.graphics.translate(x, y)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.stencil(
    function ()
      love.graphics.polygon('fill', self.hexapoly)
    end, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  local w, h = grille_image:getDimensions()
  love.graphics.draw(grille_image, - w/2, - h/2)
  love.graphics.setStencilTest()
  love.graphics.origin()
end

--- button ---

function pad.new_button(q, r, name)
  local self = setmetatable({}, pad)
  self.name = name
  self.draw     = pad.draw_button
  self.pressed  = pad.pressed_button
  self.moved    = pad.moved_button
  self.released = pad.released_button
  return self
end

function pad:draw_button(x, y)
  love.graphics.setFont(self.font)
  love.graphics.setColor(0.43,0.43,0.43)
  love.graphics.translate(x, y)
  love.graphics.polygon('fill', self.hexapoly)
  love.graphics.setColor(self.font_color)
  love.graphics.print(self.name, -self.font:getWidth(self.name)/2, -self.font:getHeight()/2)
  love.graphics.origin()
end

local octave_tracker = 0
local octave_pitch = 0
local octave_hi = synth.new(0.3)
local octave_lo = synth.new(0.3)

function pad:pressed_button()
  octave_tracker = 0
  octave_hi.sample:setPitch(synth[1].sample:getPitch() * 2)
  octave_lo.sample:setPitch(synth[1].sample:getPitch() / 2)
end

function pad:moved_button(dx, dy)
  octave_tracker = octave_tracker - dy / 100
  octave_tracker = max(-1, min(1, octave_tracker))
  octave_hi.sample:setVolume(max(0, octave_tracker))
  octave_lo.sample:setVolume(-min(0, octave_tracker))

  for i,s in ipairs(synth) do
    local pitch = s.sample:getPitch() * (1 + dx / 300)
    s.sample:setPitch(pitch)
  end
end

function pad:released_button()
  octave_hi.sample:setVolume(0)
  octave_lo.sample:setVolume(0)
end

return pad