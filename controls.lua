local controls = {}

local l = require('lume')

controls.readTilt = function() return 0, 0, 0 end -- stub
local tiltP = {0,0,0}

local minPressure =  math.huge
local maxPressure = -math.huge

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

function controls.process(s)
  s.touches = {}

  local touches = love.touch.getTouches()
  for _,id in ipairs(touches) do
    local x, y = love.touch.getPosition(id)
    s.touches[id] = {x, y}
    local pressure = love.touch.getPressure(id)
    maxPressure = math.max(maxPressure, pressure)
    minPressure = math.min(minPressure, pressure)
    if minPressure < maxPressure then
      -- eumulate note velocity with surface area of touch
      s.touches[id].pressure = l.remap(pressure, minPressure, maxPressure, 0, 1)
      s.pressureSupport = true
    else  -- if same, let's not div by 0 (CPU might explode)
      s.touches[id].pressure = 1
      s.pressureSupport = false
    end
  end

  s.tilt = {0,0,0}
  s.tilt = {controls.readTilt()}

  -- simple IIR low-pass filtering of tilt
  local a0 = 0.05
  s.tilt.lp = {}
  for i,v in ipairs(s.tilt) do
    s.tilt.lp[i] = s.tilt[i] * a0 + tiltP[i] * (1 - a0)
    tiltP[i] = s.tilt.lp[i]
  end

  return s
end

return controls