local patch = {}

-- this is "bare bones" minimal patch to use as reference, documentation and
-- as possible starting point for new patches
  -- comments are extracted for easier deletion

-- in short, the Hexpress flow is CONTROLS-INTERPRETERS-PATCH-SYNTHESIZER
-- patch can instantiate and control interpreters and synthesizers as needed

-- this is utility library with bunch of helpful math
local l = require('lume')
local sampler = require('sampler')
local hexpad = require('hexpad')

local keyboard
local tone

-- keyboard uses hexpad as a method for inputing notes
-- sampler gives sound to our notes, it is heavily customizable and controllable
  -- first give list of soundfiles and context when to use (transpose, velocity)
  -- then give basic settings like envelope,
function patch.load()
  keyboard = hexpad.new()
  tone = sampler.new({
    {path='bones/nsynth_bass_synthetic_1.wav', velocity=0.1},
    {path='bones/nsynth_bass_synthetic_3.wav', velocity=0.5},
    {path='bones/nsynth_bass_synthetic_5.wav', velocity=0.9},
    envelope = { attack = 0.20, decay = 0.50, sustain = 0.85, release = 0.35 },
  })
end



-- scan for touches and add note information
-- here we have chance to shape the sound by manipulating existing information
    -- let's control volume with y tilt
    -- we remap the tilt in range [-1, 1] into change of volume in range of [0, 1]
-- react to note changes by playing sounds
function patch.process(s)
  keyboard:interpret(s)
  tone.masterVolume = l.remap(s.tilt[2], -1, 1, 0, 0.5)
  tone:update(s.dt, s.touches)
end

-- use hexpad's default drawing method, here we could also visualize other stuff
function patch.draw(s)
  keyboard:draw(s)
end

-- icon drawn on selection screen, that can be animated with time
-- everything outside unit circle is cut out
-- draw dark gray background
-- draw light gray circle with oscillating radius
function patch.icon(time)
  love.graphics.setColor(0.3, 0.3, 0.3)
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  local r = 0.5 + 0.02 * math.cos(time * 25)
  love.graphics.setColor(0.8, 0.8, 0.8)
  love.graphics.circle('fill', 0, 0, r)
end

return patch