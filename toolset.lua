local controls = require('controls')
local l = require('lume')

local sw, sh = love.graphics.getDimensions()

local log_entries = {}
local log_lines = 20
local tracking = {}

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
  love.graphics.setColor(1, 1, 1)
  local line = 0
  for k,v in pairs(tracking) do
    love.graphics.print(string.format(k,v), sw*4/5, 5 + line * fontSize)
    line = line + 1
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

-- usage:   log(speed)
-- usage:   log('data: ', speed, x, y)
function log(...)
  local arg={...}
  if not moduleInitialized then init() end
  local line
  if #arg > 1 then
    line = table.concat(arg, ", ")
  else
    line = tostring(arg[1])
  end
  --print(line)
  log_entries[#log_entries + 1] = line
end

-- usage:   logf('speed: %1.2f m/s', speed)
function logf(s, ...)
  line = string.format(s, ...)
  print(line)
  log_entries[#log_entries + 1] = line
end

-- usage:   track('speed: %1.2f m/s', self.speed)
function track(format, value)
  tracking[format] = value
end

function drawTable(t, x, y)
  local tabSize = 20 -- px
  local x = x or sw * 4 / 5
  local y = y or 5 + 4 * fontSize
  --love.graphics.setFont(font)
  love.graphics.setColor(1, 1, 1)
  for k,v in pairs(t) do
    if type(v) == 'table' then
      love.graphics.print(tostring(k), x, y)
      y = y + fontSize
      x, y = drawTable(v, x + tabSize, y)
      x = x - tabSize
    else
      local line
      if type(v) == 'number' then
        line = string.format('%s: %1.3f', k, v)
      else
        line = string.format('%s: %1s', k, v)
      end
      love.graphics.print(line, x, y)
    end
    y = y + fontSize
  end
  return x, y
end

function addDraw(f)
  if not moduleInitialized then init() end
  table.insert(draw_functions, f)
end


if love.system.getOS() ~= 'Android' then
  log_lines = 50
end
