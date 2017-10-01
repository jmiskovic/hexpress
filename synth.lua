local synth = {}

synth.__index = synth

function synth.new()
  local self = setmetatable({}, synth)
  self.A = 0.1 -- attack
  self.D = 0.1 -- decay
  self.S = 0.9 -- sustain
  self.R = 0.5 -- release
  self.pad = {math.huge, math.huge}
  self.noteOn = nil
  self.noteOff = nil
  self.sample = love.audio.newSource('strings.wav')
  self.sample:setLooping(true)
  self.sample:setVolume(0)
  self.sample:play()
  return self
end

function synth:startNote(pitch, q, r)
  self.noteOn = 0
  self.noteOff = nil
  self.sample:setPitch(pitch)
  self.pad = {q, r}
end

function synth:stopNote()
  self.noteOff = self.noteOn
  self.pad = {math.huge, math.huge}
end

-- https://www.desmos.com/calculator/wp88j1ojhu
function synth:adsr()
  local vol = 0
  local state = 'mute'
  --if self.NoteOff then
  --  if self.NoteOff > self.R then -- mute
  --    vol = 0
  --    self.noteOn = nil
  --    self.noteOff = nil
  --    state = 'mute'
  --  else -- release
  --    vol = (self.R - self.NoteOff) / self.R
  --    state = 'release'
  --  end
  --elseif self.noteOn and self.noteOn > self.A then -- decay and sustain
  --  vol = math.max(self.S, 1 - (1 - self.S) * (self.D - self.noteOn + self.A) / self.D)
  --  state = 'decay/sustain'
  --elseif self.noteOn then -- attack
  --  vol = 1 - (self.A - self.noteOn) / self.A
  --  state = 'attack'
  --end

  if not self.noteOn then return 0, 'mute' end

  local A = self.noteOn / self.A
  local D = (self.S - 1) / self.D * (self.noteOn - self.A) + 1
  local S = self.S
  local O = self.noteOff and self.noteOff or 15
  local R = -self.S / self.R * (self.noteOn - O) + self.S
  vol = math.max(math.min(A, math.max(D, math.min(S, R))), 0)

  state = (self.noteOn and 'On' or '__') .. (self.noteOff and 'Off' or '___')

  return vol, state
end

function synth:update(dt)
  -- increase elapsed time from note on and note off events
  self.noteOn  = self.noteOn  and self.noteOn  + dt or nil
  -- silence note if release has expired
  -- self.noteOn  = self.noteOff < self.R  and self.noteOn  or nil
  -- self.noteOff = self.noteOff < self.R  and self.noteOff or nil
  -- update volume according to ADSR envelope

  self.sample:setVolume(self:adsr())
end

return synth