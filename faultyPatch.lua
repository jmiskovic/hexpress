local faultyPatch = {}
faultyPatch.__index = faultyPatch

local fontSize = 16
local font = love.graphics.newFont("Ubuntu-B.ttf", 16)

function faultyPatch.load()
end

function faultyPatch.new(errorText)
  return {
    load = function() end,
    process = function() end,
    draw = function()
        love.graphics.translate(-1, -0.9)
        love.graphics.scale(1/fontSize/20)
        love.graphics.setFont(font)
        love.graphics.printf(errorText, 0, 0, 20 * fontSize * 2, 'left')
      end,
    icon = function()
        love.graphics.setLineWidth(0.2)
        love.graphics.setColor(0.3, 0, 0, 1)
        love.graphics.line(-1, -1,  1,  1)
        love.graphics.line(-1,  1,  1, -1)
      end,
  }
end

return faultyPatch