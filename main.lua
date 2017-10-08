local hexgrid = require('hexgrid')
local synth = require('synth')


local sw, sh = love.graphics.getDimensions()
local hexgrid_center = {sw/2, sh/2}

local synth_count = 5
local synths = {}

grid = hexgrid.new(sw / 12.42, 5)

function love.load()
  synth.load()
  for i = 1, synth_count do
    synths[i] = synth.new()
  end
end

function love.draw()
  grid:draw(hexgrid_center[1], hexgrid_center[2])

  local x, y = love.mouse.getPosition()
  local q,r = grid:pixel_to_hex(x - hexgrid_center[1], y - hexgrid_center[2])
  grid:draw_highlight(q, r, hexgrid_center[1], hexgrid_center[2])
end

function love.update(dt)
  for i = 1, synth_count do
    synths[i]:update(dt)
  end
end

local lastnote = 0

function love.touchpressed(id, x, y, dx, dy, pressure)
  grid:touchpressed(id, x - hexgrid_center[1], y - hexgrid_center[2], dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  grid:touchmoved(id, x - hexgrid_center[1], y - hexgrid_center[2], dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  grid:touchreleased(id, x, y, dx, dy, pressure)
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
      synths[i]:stopNote()
      break
    end
  end
end

function love.keypressed(key)
end

