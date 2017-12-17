local fretboard = {}
fretboard.__index = fretboard

local l = require("lume")

fretboard.colorScheme = {
  neck    = {l.rgba(0x2f2c26ff)},
  fret    = {l.hsl(0, 0, 0.5)},
  string  = {l.hsl(0, 0, 0.5)},
  dot     = {l.rgba(0x84816bff)},
  highlight = {l.rgba(0xffffffc0)},
}

local neckWidth = 1.85  -- 1.0 is screen heightb

function fretboard.load()
end

function fretboard.new(displayNoteNames, tuning)
  local tuning_presets = {
    ['EBGDAE'] = {4, -1, -5, -10, -15, -20}, -- standard guitar
    ['EBGDAD'] = {4, -1, -5, -10, -15, -22}, -- dropped D guitar
    ['DBGDGD'] = {4, -1, -5, -10, -15, -20}, -- open G guitar
    ['GDAE']   = {-17, -22, -27, -32},       -- bass
    ['EADG']   = {4, -3, -10, -17}, -- violin
  }
  if type(tuning) == 'string' then
    tuning = tuning_presets[tuning]
  end
  local self = setmetatable({
    strings = tuning or tuning_presets['EBGDAE'], -- list of note indexes across strings
    tones   = {}
    }, fretboard)
  return self
end

-- circus = {}
-- table.insert(circus, {'fill', x, y, 0.1,
--   col = {l.hsl(stringI / #self.strings, fretI / 10, 0.5)}})
-- for i,v in ipairs(circus) do
--   love.graphics.setColor(v.col)
--   love.graphics.circle(unpack(v))
-- end

function fretboard:interpret(s)
  for id, touch in pairs(s.touches) do
    local x, y = unpack(touch)
    love.graphics.push()
      love.graphics.scale(self.scaling)
      x, y = love.graphics.inverseTransformPoint(x, y)
    love.graphics.pop()
    -- check if string is pressed, report string, fret and note
    local stringI, fretI
    stringI = l.remap(y, -neckWidth / 2, neckWidth / 2, 1, #self.strings)
    stringI = math.floor(stringI + 0.5)
    fretI = math.floor(l.remap(x, -2, 2, 0, 10))

    if stringI >= 1 and stringI <= #self.strings then
      if self.tones[id] and self.tones[id].string == stringI then
        touch.noteRetrigger = false
      else
        touch.noteRetrigger = true
        self.tones[id] = touch
      end
      touch.string = stringI
      touch.fret = fretI
      touch.note = self.strings[stringI] + touch.fret
    end
  end
  -- clean up released tones
  for id, touch in pairs(self.tones) do
    if not s.touches[id] then
      self.tones[id] = nil
    end
  end
end

local function stringY(i, stringCount)
  if stringCount == 1 then
    return 0
  else
    return l.remap( i , 1, stringCount, -neckWidth / 2, neckWidth / 2)
  end
end

function fretboard:draw(s)
  love.graphics.setColor(self.colorScheme.neck)
  love.graphics.rectangle('fill', -15, -neckWidth / 2 * 1.05, 30, neckWidth * 1.05)

  -- draw frets
  love.graphics.setLineWidth(0.05)
  for fretX = -2, 2, 0.4 do
    love.graphics.setColor(self.colorScheme.fret)
    love.graphics.line(fretX, -neckWidth / 2 * 1.05, fretX, neckWidth / 2 * 1.05)
    local dx = 0.01
    love.graphics.setColor(self.colorScheme.highlight)
    love.graphics.line(fretX + dx, -neckWidth / 2 * 1.05, fretX + dx, neckWidth / 2 * 1.05)
  end
  local fretX = -0.4 * 4
  love.graphics.setLineWidth(0.09)
  love.graphics.setColor(self.colorScheme.highlight)
  love.graphics.line(fretX, -neckWidth / 2 * 1.05, fretX, neckWidth / 2 * 1.05)
  -- dots
  love.graphics.circle('fill', 0.2, 0, 0.05)
  love.graphics.circle('fill', 1.0, 0, 0.05)
  -- draw strings
  for i = 1, #self.strings do
    local y = stringY(i, #self.strings)
    local dy = 0
    for id, touch in pairs(self.tones) do
      if touch.string == i then
        dy = 0.015 * math.sin(s.time * 50 + i)
      end
    end
    love.graphics.setLineWidth(l.remap(i, 1, #self.strings, 0.015, 0.03))
    love.graphics.setColor(self.colorScheme.string)
    love.graphics.line(-15, y, 15, y + dy)
    love.graphics.setLineWidth(l.remap(i, 1, #self.strings, 0.015 / 2, 0.03 / 2))
    love.graphics.setColor(self.colorScheme.highlight)
    love.graphics.line(-15, y, 15, y + dy)
  end

end

return fretboard