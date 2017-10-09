pad = {}
pad.__index = pad

pad.font_color = {0.13, 0.13, 0.13, 0.5}


function pad.new_tonepad()
  local self = setmetatable({}, pad)
  self.draw     = pad.draw_tonepad
  self.pressed  = pad.pressed_tonepad
  self.released = pad.released_tonepad
  return self
end

function pad:draw_tonepad(x, y, note_name)
  love.graphics.setFont(self.font)
  local gray = 0.43 - string.len(note_name) * 0.16
  love.graphics.setColor(gray + 0.1, gray + 0.2, gray)
  love.graphics.translate(x, y)
  love.graphics.polygon('fill', self.hexapoly)
  love.graphics.setColor(self.font_color)
  love.graphics.print(note_name, -self.font:getWidth(note_name)/2, -self.font:getHeight()/2)
  love.graphics.origin()
end

local grille_image = love.graphics.newImage('grille.png')

function pad:draw_grille(q, r, cx, cy)
  local x, y = self:hex_to_pixel(q, r)
  x, y = x + cx, y + cy
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


return pad