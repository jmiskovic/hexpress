hexpad = {}
hexpad.__index = hexpad

local hexgrid = require('hexgrid')


local noteIndexToName = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
local touchToQR = {}

function hexpad.new(cx, cy, scale, radius, noteOffset)
  local self = setmetatable({
      cx         = cx,
      cy         = cy,
      scale      = scale,
      radius     = radius or 3,
      noteOffset = noteOffset or 0,
    }, hexpad)

  return self
end

function hexpad:process(stream)
    -- apply hex grid to find out coordinates and desired note pitch
  for id, touch in pairs(stream.touches) do
    local x, y = unpack(touch)
    local q, r = hexgrid.pixelToHex(x, y, self.cx, self.cy, self.scale)
    local noteIndex = self:hexToNoteIndex(q, r)


    touch.qr = {q, r}
    touch.noteName = noteIndexToName[noteIndex % 12 + 1]
    touch.pitch    = math.pow(math.pow(2, 1/12), noteIndex)
    -- retrigger note if it's new touch or if existing touch has crossed into another cell
    touch.noteRetrigger = not touchToQR[id] or (touchToQR[id][1] ~= q or touchToQR[id][2] ~= r)
    touchToQR[id] = touch.qr -- store touch qr for next iteration
  end

  -- clean up perished touches
  for id, qr in pairs(touchToQR) do
    local touch = stream.touches[id]
    if not touch then
      touchToQR[id] = nil
    end
  end

  return stream
end

function hexpad:hexToNoteIndex(q, r)
  -- harmonic table layout is defined by two neighbor interval jumps:
  --  +4 semitones when going in NE direction (direction index 1)
  --  +7 semitones when going in N  direction (direction index 2)
  -- the rest of intervals follow from these two
  local intervalNE = 4
  local intervalN  = 7
  return self.noteOffset + q * intervalNE + (-q - r) * intervalN
end


return hexpad