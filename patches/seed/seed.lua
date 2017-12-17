local patch = {}

-- this is a minimal patch to use as reference, documentation and as possible
--  starting point for new patches
-- comments are extracted for easier deletion

-- in short, the Hexpress flow is CONTROLS->INTERPRETERS->PATCH->SYNTHESIZERS
--  CONTROLS read screen touches and phone tilt
--  INTERPRETERS give meaning to input, for example they assign notes to touches
--  PATCH instantiates and controls interpreters and synthesizers as needed
--  SYNTHESIZERS make sound from available information (note, pressure, envelope...)

-- this is utility library with bunch of helpful math
local l = require('lume')
local sampler = require('sampler')
local hexpad = require('hexpad')
local notes = require('notes')

local keyboard
local tone

-- use hexpad as a method for inputing notes (we could have also selected fretboard here)
-- sampler gives sound to our notes, it is heavily customizable and controllable
  -- first give list of soundfiles and context when to use (assigned note, velocity)
  -- then give basic settings like envelope, transposing and looping samples
function patch.load()
  keyboard = hexpad.new()
  tone = sampler.new({
    {path='patches/seed/nubia.ogg', notes = notes.toIndex['C4']},
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
  tone.masterVolume = l.remap(s.tilt[2], -1, 1, 0, 1)
  tone:update(s.dt, s.touches)
end

-- use hexpad's default drawing method, here we could also visualize other stuff
function patch.draw(s)
  keyboard:draw(s)
end

-- icon drawn on selection screen, that can be animated with time
  -- everything outside unit circle is cut out
  -- draw dirt background
  -- draw seed as filled brown ellipse and outlined light ellipse
function patch.icon(time)
  love.graphics.setColor(l.rgba(0xf7c65dff))
  love.graphics.rectangle('fill', -1, -1, 2, 2)
  love.graphics.rotate(-math.pi / 3)
  love.graphics.setColor(l.rgba(0x654b11ff))
  love.graphics.ellipse('fill', 0, 0, 0.4, 0.3)
  love.graphics.setLineWidth(0.05)
  love.graphics.setColor(l.rgba(0xffffff40))
  love.graphics.ellipse('line', 0, 0, 0.4, 0.27)
end

return patch