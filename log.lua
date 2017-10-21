local log_entries = {}
local log_lines = 60

local trace_entries = {}


local displayLog = true
local displayTrace = true

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
  print(actualLoveDraw)
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