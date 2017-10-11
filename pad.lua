pad = {}
pad.__index = pad

local synth = require('synth')
local log = require('log')



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

function pad.pressed_button()
end
function pad.released_button()
end

return pad