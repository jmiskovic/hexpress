local controls = require('controls')

local sw, sh = love.graphics.getDimensions()

local log_entries = {}
local log_lines = 60

local trace_entries = {}

local moduleInitialized = false -- log module is initialized lazily
local actualLoveDraw
local font
local fontSize = 16

local draw_functions = {}

local function imposterLoveDraw()
  actualLoveDraw()
  local fader = 1
  love.graphics.setFont(font)
  for i = #log_entries, #log_entries - log_lines, -1 do
      love.graphics.setColor(1, 1, 1, fader)
      love.graphics.print(log_entries[i] or '', 5, 5 + (#log_entries - i) * fontSize)
      fader = fader - 1 / log_lines
  end
  for _,v in ipairs(draw_functions) do
    v()
  end
end

local function init()
  moduleInitialized = true
  actualLoveDraw = love.draw
  love.draw = imposterLoveDraw
  font = love.graphics.newFont("Ubuntu-B.ttf", fontSize)
end

function log(s, ...)
  if not moduleInitialized then init() end
  local line = string.format(s, ...)
  print(line)
  log_entries[#log_entries + 1] = line
end

function addDraw(f)
  if not moduleInitialized then init() end
  table.insert(draw_functions, f)
end

-- tilt sensor visualization
function drawTilt()
  if not controls.tilt then return end

  local barsize = 40
  love.graphics.setFont(font)
  -- vertical bar for tilt[2] (pitch)
  love.graphics.translate(sw - 2 * barsize, sh / 2)
  love.graphics.scale(0.7)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', 0, -sh / 2, barsize, sh)
  love.graphics.setColor(1, 1, 0, 0.5)
  love.graphics.rectangle('fill', 0, 0, barsize, -sh / 2 * controls.tilt[2])
  love.graphics.print(controls.tilt[2], barsize * 1.1, -sh / 2 * controls.tilt[2])
  love.graphics.origin()
  -- horizontal bar for tilt[1] (yaw)
  love.graphics.translate(sw / 2, sh - 2 * barsize)
  love.graphics.scale(0.7)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', -sw / 2, 0, sw, barsize)
  love.graphics.setColor(1, 1, 0, 0.5)
  love.graphics.rectangle('fill', 0, 0, sw / 2 * controls.tilt[1], barsize)
  love.graphics.print(controls.tilt[1], sw / 2 * controls.tilt[1], barsize * 1.1)
  love.graphics.origin()
  -- scaling square for tilt[3] (roll)
  local barsize = 80
  love.graphics.translate(sw - 2 * barsize, sh - 2 * barsize)
  love.graphics.setColor(1, 1, 1, 0.2)
  love.graphics.rectangle('fill', -barsize / 2, -barsize / 2, barsize, barsize)
  love.graphics.setColor(1, 1, 0, 0.5)
  barsize = barsize * (controls.tilt[3] + 1)/2 -- remap -1,1 to 0,1
  love.graphics.rectangle('fill', -barsize / 2, -barsize / 2, barsize, barsize)
  love.graphics.print(controls.tilt[3], 0, 0)
  love.graphics.origin()
end

if love.system.getOS() ~= 'Android' then
  addDraw(drawTilt)
end
