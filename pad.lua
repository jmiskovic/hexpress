local pad = {}
pad.__index = pad

local synths = require('synths')
local min = math.min
local max = math.max
pad.moved = function(self, dx, dy) end -- stub

pad.size = nil
pad.synth_mapping = {}
pad.font_color = {0.13, 0.13, 0.13, 0.5}
note_names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
pad.note_offset = 4

pad.tonepad_images = {}

local scheme = {
  background    = {0.28, 0.27, 0.35, 1.00},
  pad_highlight = {0.96, 0.49, 0.26, 1.00},
  pad_surface   = {0.21, 0.21, 0.27, 1.00},
  white         = {1.00, 1.00, 1.00, 1.00},

  grille_metal   = {0.59, 0.59, 0.59},
  grille_speaker = {0.23, 0.23, 0.23},
}

love.graphics.setBackgroundColor(scheme.background)

--local octave_tracker = 0
--local octave_pressed = false
--local octave_hi = synths.new(0.3)
--local octave_lo = synths.new(0.3)

function pad.init(size)
  pad.size = size
  pad.font = love.graphics.newFont("Ubuntu-B.ttf", size/2)
end

-- harmonic note grid from QR coordinate
function pad.hex_to_note(q, r)
    return q*4 + (-q-r)*7 + pad.note_offset
end

function modify_pitch(synth, mod)
  local pitch = synths.sample:getPitch() * mod
  synth.sample:setPitch(pitch)
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
  if not pad.tonepad_images[self.name] then
    pad.tonepad_images[self.name] = pad.prepare_tonepad(self.name)
  end
  return self
end

function pad.prepare_tonepad(text)
  local canvas = love.graphics.newCanvas(pad.size * 2, pad.size * 2)
  love.graphics.setFont(pad.font)
  love.graphics.setCanvas(canvas)
  love.graphics.translate(pad.size, pad.size)
  love.graphics.scale(0.95)
  love.graphics.setColor(scheme.pad_surface)
  love.graphics.polygon('fill', pad.hexapoly)
  love.graphics.origin()
  love.graphics.setColor(scheme.background)
  love.graphics.print(text, pad.size - pad.font:getWidth(text)/2, pad.size - pad.font:getHeight()/2)
  love.graphics.setCanvas()
  return canvas
end

function lerp(a, b, v)
  return a + (b - a) * v
end

function pad:draw_tonepad(x, y)
  local image = pad.tonepad_images[self.name]
  love.graphics.translate(x, y)
  local volume = (pad.synth_mapping[self] and pad.synth_mapping[self].volume or 0)
  love.graphics.scale(1 + 0.15 * volume)
  love.graphics.setColor(scheme.white)
  love.graphics.draw(image, - image:getWidth() / 2, - image:getHeight() / 2)
  if volume > 0 then
    scheme.pad_highlight[4] = volume
    love.graphics.setColor(scheme.pad_highlight)
    love.graphics.scale(0.8)
    love.graphics.setLineWidth(16)
    love.graphics.polygon('line', pad.hexapoly)
  end
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

local grille_image -- = love.graphics.newImage('grille.png')

function pad.prepare_grille()
  local canvas = love.graphics.newCanvas(pad.size * 2, pad.size * 2)
  love.graphics.setCanvas(canvas)
  love.graphics.translate(pad.size, pad.size)
  love.graphics.setColor(scheme.grille_metal)
  love.graphics.polygon('fill', pad.hexapoly)
  love.graphics.setColor(scheme.grille_speaker)
  local d = 20
  for x =-5,5 do
    for y =-5,5 do
      if y % 2 == 0 then
        love.graphics.circle('fill', x * d, y * d, d / 2.1)
      else
        love.graphics.circle('fill', (x + 0.5) * d, y * d, d / 2.1)
      end
    end
  end

  --love.graphics.setLineWidth(16)
  --love.graphics.setColor(0.5, 0.5, 0.5, 0.4)
  --love.graphics.polygon('line', pad.hexapoly)
  love.graphics.origin()
  love.graphics.setCanvas()
  return canvas
end

function pad.new_grille(q, r)
  self = pad.new_tonepad(q, r)
  self.draw     = pad.draw_grille
  if not grille_image then
    grille_image = pad.prepare_grille()
  end
  return self
end

function pad:draw_grille(x, y)
  love.graphics.translate(x, y)
  love.graphics.stencil(
    function ()
      love.graphics.polygon('fill', self.hexapoly)
    end, "replace", 1)
  love.graphics.setStencilTest("greater", 0)
  love.graphics.setColor(1, 1, 1, 1)
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
  love.graphics.setFont(pad.font)
  love.graphics.translate(x, y)
  love.graphics.setColor(scheme.gray)
  love.graphics.polygon('fill', self.hexapoly)
  love.graphics.setColor(scheme.orange)
  local tx, ty = -pad.font:getWidth(self.name)/2, -pad.font:getHeight()/2
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