local configScreen = require('configScreen')
local hexgrid = require('hexgrid')
local synth = require('synth')

local pitch_shifter = {read = 0, lastval = 0, pitch = 0}

local sw, sh = love.graphics.getDimensions()
local swh, shh = sw / 2, sh/2

local synth_count = 5
local synths = {}

grid = hexgrid.new(sw/17, math.floor(swh / 50))

function love.load()
  --loop:play()
  local joysticks = love.joystick.getJoysticks()

  for i, joystick in ipairs(joysticks) do
    if joystick:getName() == 'Android Accelerometer' then
      pitch_shifter.read = function() return joystick:getAxis(2) end
      break
    end
  end

  for i = 1, synth_count do
    synths[i] = synth.new()
  end
end

function love.draw()
  grid:draw(swh, shh)

  local x, y = love.mouse.getPosition()
  local q,r = grid:pixel_to_hex(x - swh, y - shh)
  grid:draw_hex(q, r, swh, shh)
  --love.graphics.print(love.touch.getPressure(1), 5, 60)
end

function love.update(dt)
--  local val = pitch_shifter.read() or 0
--  local pitch = val - pitch_shifter.lastval
--  pitch_shifter.lastval = val
--  pitch_shifter.pitch = pitch_shifter.pitch * 0.8 + pitch * 0.2
--  loop:setVolume(loop:getVolume() - pitch_shifter.pitch)
  for i = 1, synth_count do
    synths[i]:update(dt)
  end
end

local lastnote = 0

function love.touchpressed(id, x, y, dx, dy, pressure)
  grid:touchpressed(id, x - swh, y - shh, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  grid:touchmoved(id, x - swh, y - shh, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  grid:touchreleased(id, x, y, dx, dy, pressure)
  --loop:stop()
end

function grid:cellpressed(q, r)
  local n = grid:hex_to_note(q, r)
  --love.system.vibrate(0.01)
  local pitch = math.pow(math.pow(2, 1/12), n-12)
  -- reuse synth that's not playing, or has longest note duration (preferably already released note)
  local synths_sorted = {}
  for i = 1, synth_count do synths_sorted[i] = synths[i] end
  table.sort(synths_sorted, function(a, b)
    ac = (a.noteOn or math.huge) + (a.noteOff and 15 or 0)
    bc = (b.noteOn or math.huge) + (b.noteOff and 15 or 0)
    return ac > bc
    end)
  synths_sorted[1]:startNote(pitch, q, r)
end

function grid:cellreleased(q, r)
  for i = 1, synth_count do
    if synths[i].pad[1] == q and synths[i].pad[2] == r then
      synths[i]:stopNote(q, r)
      break
    end
  end
end

function love.keypressed(key)
  if key == 'escape' then
    --love.event.quit()
    configScreen.enter()
  end
end

