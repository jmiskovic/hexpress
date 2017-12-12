local notes = {}

-- map from index integer to note name string
notes.toName = setmetatable({[0] = 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'},
                           {__index=function(t, i) return t[i % 12] end})

-- map from name string to index (C4 -> 0, C#4 -> 1)
notes.toIndex = {}
for i=-24,24 do
  notes.toIndex[notes.toName[i] .. math.floor(i / 12 + 4)] = i
end

-- map from index to pitch (C5 -> 1.0, C5 -> 2.0)
function notes.toPitch(noteIndex)
  -- equal temperament
  return math.pow(math.pow(2, 1/12), noteIndex)
end

--print(notes.toName[0], notes.toName[12], notes.toName[24])
--print(notes.toIndex['C3'], notes.toIndex['C4'], notes.toIndex['C#4'])
--print(notes.toPitch(0), notes.toPitch(12), notes.toPitch(-12))

return notes