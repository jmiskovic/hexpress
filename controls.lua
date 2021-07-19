local controls = {}

local l = require('lume')

controls.readTilt = function() return 0, 0, 0 end -- stub

controls.frozen = false   -- ability to freeze tilt reading
local tiltP = {0,0,0}
local activeTouches = {}

function controls.load()
  -- finding accelerometer
  local joysticks = love.joystick.getJoysticks()
  for _, joystick in ipairs(joysticks) do
    if joystick:getName() == 'Android Accelerometer' then
      controls.readTilt = function()
          return joystick:getAxis(1), joystick:getAxis(2), joystick:getAxis(3)
        end
      break
    end
  end
end


local lastId = 0

local function nextId()
  lastId = lastId + 1
  return lastId
end


function controls.process(s)
  local frameTouches = {} -- temp map for pruning non-active touches
  s.touches = {}
  local touches = love.touch.getTouches() -- returns array of 'light userdata' ids, guaranteed to be unique only for duration of touch
  -- udid is user data id that Love2D provides, it is not Lua datatype and not serializable
  -- seqid is integer id that is locally generated and sequential

  for _,udid in ipairs(touches) do
    local x, y = love.touch.getPosition(udid)
    local seqid = activeTouches[udid] or nextId()
    activeTouches[udid] = seqid
    frameTouches[udid] = true
    s.touches[seqid] = {x, y}
  end
  -- prune active touches that dissapeared from this frame list of touches
  for udid, seqid in pairs(activeTouches) do
    if not frameTouches[udid] then
      activeTouches[udid] = nil
    end
  end

  if controls.frozen then
    s.tilt    = tiltP
    s.tilt.lp = tiltP
  else
    s.tilt = {0,0,0}
    s.tilt = {controls.readTilt()}
    -- simple IIR low-pass filtering of tilt
    local a0 = 0.05
    s.tilt.lp = {}
    for i,v in ipairs(s.tilt) do
      s.tilt.lp[i] = s.tilt[i] * a0 + tiltP[i] * (1 - a0)
      tiltP[i] = s.tilt.lp[i]
    end
  end

  return s
end

return controls