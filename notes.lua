local notes = {}

-- map from index integer to note name string
notes.toName = setmetatable({[0] = 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'},
                           {__index=function(t, i) return t[i % 12] end})

-- map from name string to index (C4 -> 0, C#4 -> 1)
notes.toIndex = {}
for i=-48,48 do
  notes.toIndex[notes.toName[i] .. math.floor(i / 12 + 4)] = i
end

local justRatios = {
  1/1,   -- perfect unison
  16/15, -- minor second
  9/8,   -- major second
  6/5,   -- minor third
  5/4,   -- major third
  4/3,   -- perfect fourth
  45/32, -- augmented fourth
  64/45, -- diminished fifth
  3/2,   -- perfect fifth
  8/5,   -- minor sixth
  5/3,   -- major sixth
  16/9,  -- minor seventh
  15/8   -- major seventh
}

-- map from index to pitch (C4 -> 1.0, C5 -> 2.0)
function notes.toPitch(noteIndex)
  -- equal temperament
  return math.pow(math.pow(2, 1/12), noteIndex)
end

--print(notes.toName[0], notes.toName[12], notes.toName[24])
--print(notes.toIndex['C3'], notes.toIndex['C4'], notes.toIndex['C#4'])
--print(notes.toPitch(0), notes.toPitch(12), notes.toPitch(-12))

return notes