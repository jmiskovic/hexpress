-- implementation of rectangular grid note layout with configurable relation between neighbor notes

local fretboard = {}
fretboard.__index = fretboard

local l = require("lume")

fretboard.neckHeight = 0.98  -- with 1.0 being half-screen height
fretboard.neckWidth = 4
fretboard.fretWidth = 0.4

function fretboard.load()
end

function fretboard.new(displayNoteNames, tuning)
  -- tuning names are from highest to lowest pitch, but note index tables
  -- are from lowest to highest (a bit confusing)
  local tuning_presets = {
    ['EBGDAE'] = {-20, -15, -10,  -5, -1, 4}, -- standard guitar
    ['EBGDAD'] = {-22, -15, -10,  -5, -1, 4}, -- dropped D guitar
    ['DBGDGD'] = {-20, -15, -10,  -5, -1, 4}, -- open G guitar
    ['GDAE']   = {-32, -27, -22, -17},         -- bass
    ['EADG']   = {-17, -10,  -3,   4},         -- violin
  }
  if type(tuning) == 'string' then
    tuning = tuning_presets[tuning]
  end
  local self = setmetatable({
    strings = tuning or tuning_presets['EBGDAE'], -- list of note indexes across strings
    activeNotes   = {},
    colorScheme = {
      neck    = {l.rgba(0x2f2c26ff)},
      fret    = {l.hsl(0, 0, 0.5)},
      string  = {l.hsl(0, 0, 0.5)},
      dot     = {l.rgba(0xffffffc0)},
      light   = {l.rgba(0xffffffc0)},
      shade   = {l.rgba(0x00000010)},
    }
    }, fretboard)
  -- calculate positions of C notes
  self.cNotePositions = {}
  for string = 1, #self.strings do
    for fret = 0, 10 do
      if self:toNoteIndex(fret, string) % 12 == 0 then
        table.insert(self.cNotePositions,  {self:toX(fret), self:toY(string)})
      end
    end
  end
  return self
end

function fretboard:toNoteIndex(fret, string)
  return self.strings[string] + fret
end

function fretboard:interpret(s)
  for id, touch in pairs(s.touches) do
    local x, y = unpack(touch)
    love.graphics.push()
      love.graphics.scale(self.scaling)
      x, y = love.graphics.inverseTransformPoint(x, y)
    love.graphics.pop()
    if y < self.neckHeight and y > -self.neckHeight and x < 2 and x > -2 then
      -- check if string is pressed, report string, fret and note
      local stringI, fretI
      stringI = l.remap(y, self.neckHeight, -self.neckHeight, 1, #self.strings)
      stringI = math.floor(stringI + 0.5)
      fretI = math.ceil(l.remap(x, -self.neckWidth/2, self.neckWidth/2, 0, self.neckWidth / self.fretWidth))

      if stringI >= 1 and stringI <= #self.strings then
        if self.activeNotes[id] and self.activeNotes[id].string == stringI then
          touch.noteRetrigger = false
        else
          touch.noteRetrigger = true
          self.activeNotes[id] = touch
        end
        touch.string = stringI
        touch.fret = fretI
        touch.note = self:toNoteIndex(fretI, stringI)
      end
    end
  end
  -- clean up released activeNotes
  for id, touch in pairs(self.activeNotes) do
    if not s.touches[id] then
      self.activeNotes[id] = nil
    end
  end
end

function fretboard:toX(fret)
  return l.remap(fret, 0, self.neckWidth / self.fretWidth, -self.neckWidth/2, self.neckWidth/2)
end

function fretboard:toY(string)
  local stringCount = #self.strings
  if stringCount == 1 then
    return 0
  else
    return l.remap(string, 1, stringCount, self.neckHeight * 0.9, -self.neckHeight * 0.9)
  end
end

function fretboard:draw(s)
  local heightReduction = 0.99
  love.graphics.setColor(self.colorScheme.neck)
  love.graphics.rectangle('fill', -15, -self.neckHeight * heightReduction, 30, self.neckHeight * heightReduction * 2)

  -- draw frets
  love.graphics.setLineWidth(0.125 * self.fretWidth)
  for toX = -self.neckWidth/2, self.neckWidth/2, self.fretWidth do
    love.graphics.setColor(self.colorScheme.shade)
    love.graphics.line(toX + 0.05, -self.neckHeight, toX + 0.05, self.neckHeight)
    love.graphics.setColor(self.colorScheme.fret)
    love.graphics.line(toX, -self.neckHeight, toX, self.neckHeight)
    local dx = 0.01
    love.graphics.setColor(self.colorScheme.light)
    love.graphics.line(toX + dx, -self.neckHeight, toX + dx, self.neckHeight)
  end
  -- draw strings
  for i = 1, #self.strings do
    local y = self:toY(i, #self.strings)
    local dy = 0
    for id, touch in pairs(self.activeNotes) do
      if touch.string == i then
        dy = 0.015 * math.sin(s.time * 50 + i)
      end
    end
    love.graphics.setLineWidth(l.remap(i, 0, #self.strings+1, 0.04, 0.01))
    love.graphics.setColor(self.colorScheme.string)
    love.graphics.line(-2, y, 2, y + dy)
    love.graphics.setLineWidth(l.remap(i, 0, #self.strings+1, 0.04 / 2, 0.01 / 2))
    love.graphics.setColor(self.colorScheme.light)
    love.graphics.line(-2, y, 2, y + dy)
  end

end

return fretboard