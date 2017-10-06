local synth = {}

synth.__index = synth

synth.effect = nil

-- init synth system
function synth.load()
  love.audio.setEffect('myeffect', {type='echo', delay=0.35, feedback=0.3, volume=0.4, spread=0.5, tapdelay=0.0, damping=0.5})
  synth.effect = love.audio.getEffect('myeffect')
end

function synth.new(a, d, s, r)
  local self = setmetatable({}, synth)
  self.A = a or 0.5 -- attack
  self.D = d or 0.3 -- decay
  self.S = s or 0.8 -- sustain
  self.R = r or 0.5 -- release
  self.pad = {math.huge, math.huge}
  self.noteOn = nil
  self.noteOff = nil
  self.sample = love.audio.newSource(love.sound.newDecoder('strings.wav'))
  self.sample:setLooping(true)
  self.sample:setVolume(0)
  self.sample:setEffect('myeffect')
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
  -- update volume according to ADSR envelope
  self.sample:setVolume(self:adsr())
end

return synth