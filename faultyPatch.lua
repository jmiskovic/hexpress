local faultyPatch = {}
faultyPatch.__index = faultyPatch

function faultyPatch.new(errorText)
  local self = setmetatable({}, faultyPatch)
  return self
end

function faultyPatch:icon()
  love.graphics.setLineWidth(0.2)
  love.graphics.setColor(0.3, 0, 0, 1)
  love.graphics.line(-1, -1,  1,  1)
  love.graphics.line(-1,  1,  1, -1)
end

return faultyPatch