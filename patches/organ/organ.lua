local patch = { name = 'organ' }

local sampler = require('sampler')
local hexpad = require('hexpad')
local efx = require('efx')
local l = require('lume')

local colorScheme = {
  pipe  = {l.rgba(0xfafa50ff)},
  shade = {l.rgba(0xffffffa0)},
  lip   = {l.rgba(0x606010ff)},
  white = {l.rgba(0xffffff50)},
  black = {l.rgba(0x00000050)},
}

local keyboard
local samplerLoop, samplerStart

function patch.load()
  keyboard = hexpad.new()
  efx.setDryVolume(0.5)
  efx.addEffect(efx.tremolo)
  samplerLoop = sampler.new({
    {path='patches/organ/Rode_Pedal_10.ogg', note= -3},
    {path='patches/organ/Rode_Pedal_13.ogg', note=  0},
    {path='patches/organ/Rode_Pedal_16.ogg', note=  3},
    {path='patches/organ/Rode_Pedal_19.ogg', note=  6},
    {path='patches/organ/Rode_Pedal_22.ogg', note=  9},
    {path='patches/organ/Rode_Pedal_25.ogg', note= 12},
    {path='patches/organ/Rode_Pedal_28.ogg', note= 15},
    {path='patches/organ/Rode_Pedal_31.ogg', note= 18},
    looped = true,
    envelope = { attack = 0.1, decay = 0.50, sustain = 0.85, release = 0.35 },
  })

  function keyboard:drawCell(q, r, s)
    -- shape
      local note = self:hexToNoteIndex(q, r)
      local text = self.noteIndexToName[note % 12 + 1]
      local keyColor = #text > 1 and colorScheme.black or colorScheme.white
      love.graphics.setColor(keyColor)
      love.graphics.scale(0.90)
      love.graphics.polygon('fill', self.shape)
end

end

function patch.process(s)
  keyboard:interpret(s)
  samplerLoop:update(s.dt, s.touches)
  efx.tremolo.frequency = l.remap(s.tilt.lp[1], -0.3, 0.3, 0, 8, 'clamp')
  efx.reverb.decaytime = l.remap(s.tilt.lp[2], 1, 0, 1, 10)
  return s
end

function patch.draw(s)
  keyboard:draw(s)
end

function patch.icon(time)
  local width = 0.6
  local off = math.sin(time) * 0.05
  for x=-1.1, 1.1, width do
    -- pipe
    love.graphics.setColor(colorScheme.pipe)
    love.graphics.rectangle('fill', x, -1, width*0.9, 2)
    -- shading
    love.graphics.setColor(colorScheme.shade)
    love.graphics.rectangle('fill', x + width * 0.05, -1, width * 0.3 + off, 2)
    -- lip
    love.graphics.setColor(colorScheme.lip)
    love.graphics.ellipse('fill', x + width * 0.5, 0.5 + math.sin(x + time)*0.05, width * 0.35, width * 0.15)
  end
end

return patch