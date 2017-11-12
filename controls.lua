local controls = {}

controls.readTilt = function() return 0, 0, 0 end -- stub

function controls.load()
  -- finding accelerometer
  local joysticks = love.joystick.getJoysticks()
  for i, joystick in ipairs(joysticks) do

    if joystick:getName() == 'Android Accelerometer' then
      controls.readTilt = function()
          return joystick:getAxis(1), joystick:getAxis(2), joystick:getAxis(3)
        end
      break
    end

  end
end

function controls.process(stream)
  stream.touches = {}
  stream.tilt = {0,0,0}

  local touches = love.touch.getTouches()
  for _,id in ipairs(touches) do
    local x, y = love.touch.getPosition(id)
    stream.touches[id] = {x, y}
    stream.touches[id].pressure = love.touch.getPressure(id)
  end

  stream.tilt = {controls.readTilt()}

  return stream
end

-- legacy
controls.tilt = {0,0,0}

return controls