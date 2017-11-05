local controls = {

tilt = {0,0,0},

}

local readTilt

function controls.load()
  -- finding acc
  local joysticks = love.joystick.getJoysticks()
  for i, joystick in ipairs(joysticks) do
    if joystick:getName() == 'Android Accelerometer' then
      readTilt = function() return joystick:getAxis(1), joystick:getAxis(2), joystick:getAxis(3) end
      break
    end
  end

  readTilt = readTilt or function() return unpack(controls.tilt) end
end

function controls.update(dt)
  controls.ptilt = {controls.tilt[1], controls.tilt[2], controls.tilt[3]}
  controls.tilt = {readTilt()}
end

return controls