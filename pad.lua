pad = {}
pad.__index = pad

local synths = require('synths')
local min = math.min
local max = math.max
pad.moved = function(self, dx, dy) end -- stub

pad.synth_mapping = {}
pad.font_color = {0.13, 0.13, 0.13, 0.5}
note_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
pad.note_offset = 4

local scheme = {
  dark_gray  = {0.219, 0.200, 0.215},
  orange     = {0.768, 0.443, 0.184},
  green      = {0.388, 0.501, 0.372},
  light_gray = {0.733, 0.690, 0.694},
  gray       = {0.337, 0.329, 0.329, 0.3},
  red        = {0.686, 0.058, 0.117},
}

local octave_tracker = 0
local octave_pressed = false
local octave_hi = synths.new(0.3)
local octave_lo = synths.new(0.3)


-- harmonic note grid from QR coordinate
function pad.hex_to_note(q, r)
    return q*4 + (-q-r)*7 + pad.note_offset
end

function modify_pitch(synth, mod)
  local pitch = synths.sample:getPitch() * mod
  synth.sample:setPitch(pitch)
end

function pad.init_fonts(size)
  pad.font = love.graphics.newFont("Ubuntu-B.ttf", size/2)
end


--- tonepad ---

function pad.new_tonepad(q, r)
  local self = setmetatable({}, pad)
  self.draw     = pad.draw_tonepad
  self.pressed  = pad.pressed_tonepad
  self.moved    = pad.moved_tonepad
  self.released = pad.released_tonepad
  local note = pad.hex_to_note(q, r)
  self.name = note_names[note % 12 +1]
  self.pitch = math.pow(math.pow(2, 1/12), note)
  pad.synth_mapping[self] = nil -- index of selected synth, valid while pad is pressed
  return self
end

function pad:draw_tonepad(x, y)
  love.graphics.setFont(self.font)
  love.graphics.translate(x, y)
  love.graphics.scale(1 - (pad.synth_mapping[self] and 0.2 * pad.synth_mapping[self].volume or 0))
  local gray = string.len(self.name) > 1 and scheme.dark_gray or scheme.light_gray
  love.graphics.setColor(gray)
  love.graphics.polygon('fill', self.hexapoly)
  love.graphics.setColor(scheme.gray)
  love.graphics.print(self.name, -self.font:getWidth(self.name)/2, -self.font:getHeight()/2)
  love.graphics.origin()
end

function pad:pressed_tonepad()
  local synth = synths.get_unused()
  -- remove previous association with pad
  for p,s in pairs(pad.synth_mapping) do
    if s == synth then pad.synth_mapping[p] = nil end
  end
  if pad.synth_mapping[self] then
    self:released_tonepad()
  end
  pad.synth_mapping[self] = synth
  synth:startNote(self.pitch)
end

function pad:moved_tonepad(dx,dy)
  if false and pad.synth_mapping[self] and octave_pressed then
    local dp = (1 - dy / 250)
    modify_pitch(pad.synth_mapping[self], dp)
    modify_pitch(octave_lo, dp)
    modify_pitch(octave_hi, dp)
  end
end

function pad:released_tonepad()
  if pad.synth_mapping[self] then
    pad.synth_mapping[self]:stopNote()
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
  love.graphics.translate(x, y)
  love.graphics.setColor(scheme.gray)
  love.graphics.polygon('fill', self.hexapoly)
  love.graphics.setColor(scheme.orange)
  local tx, ty = -self.font:getWidth(self.name)/2, -self.font:getHeight()/2
  if x > love.graphics.getWidth()/2 then
    love.graphics.print(self.name, tx-30, ty)
  else
    love.graphics.print(self.name, tx+30, ty)
  end
  love.graphics.origin()
end

function pad:pressed_button()
  octave_tracker = 0
  octave_pressed = true
  octave_hi.sample:setPitch(synths[1].sample:getPitch() * 2)
  octave_lo.sample:setPitch(synths[1].sample:getPitch() / 2)
end

function pad:moved_button(dx, dy)
  octave_tracker = octave_tracker - dy / 100
  octave_tracker = max(-1, min(1, octave_tracker))
  octave_hi.sample:setVolume(max(0, octave_tracker))
  octave_lo.sample:setVolume(-min(0, octave_tracker))
end

function pad:released_button()
  octave_pressed = false
  octave_hi.sample:setVolume(0)
  octave_lo.sample:setVolume(0)
end

return pad