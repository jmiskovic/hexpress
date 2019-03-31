local patch = {}

local sampler = require('sampler')
local hexgrid = require('hexgrid')
local keyboard = require('hexpad')
local efx = require('efx')
local l = require('lume')

local colorScheme = {
  pipe  = {l.rgba(0xccad00ff)},
  shade = {l.rgba(0xffffff50)},
  lip   = {l.rgba(0x4e480cff)},
  background = {0,0,0},
}

function patch.load()
  patch.keyboard = keyboard.new(true, 0, 10, 2)
  efx.setDryVolume(0.5)
  efx.addEffect(efx.tremolo)
  efx.tremolo.volume = .7
  efx.reverb.decaytime = 4

  patch.manOp = sampler.new({
    {path='patches/organ/Rode_Man3Open_04.ogg', note= -9},
    {path='patches/organ/Rode_Man3Open_07.ogg', note= -6},
    {path='patches/organ/Rode_Man3Open_10.ogg', note= -3},
    {path='patches/organ/Rode_Man3Open_13.ogg', note=  0},
    {path='patches/organ/Rode_Man3Open_16.ogg', note=  3},
    {path='patches/organ/Rode_Man3Open_19.ogg', note=  6},
    {path='patches/organ/Rode_Man3Open_22.ogg', note=  9},
    {path='patches/organ/Rode_Man3Open_25.ogg', note= 12},
    {path='patches/organ/Rode_Man3Open_28.ogg', note= 15},
    {path='patches/organ/Rode_Man3Open_31.ogg', note= 18},
    {path='patches/organ/Rode_Man3Open_34.ogg', note= 21},
    envelope = { attack = 0.1, decay = 0.50, sustain = 0.85, release = 0.4 },
  })

  patch.pedal = sampler.new({
    {path='patches/organ/Rode_Pedal_10.ogg', note= -3},
    {path='patches/organ/Rode_Pedal_13.ogg', note=  0},
    {path='patches/organ/Rode_Pedal_16.ogg', note=  3},
    {path='patches/organ/Rode_Pedal_19.ogg', note=  6},
    {path='patches/organ/Rode_Pedal_22.ogg', note=  9},
    {path='patches/organ/Rode_Pedal_25.ogg', note= 12},
    {path='patches/organ/Rode_Pedal_28.ogg', note= 15},
    {path='patches/organ/Rode_Pedal_31.ogg', note= 18},
    looped = true,
    envelope = { attack = 0.1, decay = 0.50, sustain = 0.85, release = 0.4 },
  })
  love.graphics.setBackgroundColor(colorScheme.background)
  patch.keyboard.colorScheme.background    = {l.rgba(0x000000ff)}
  patch.keyboard.colorScheme.highlight     = {l.rgba(0xd3660aff)}
  patch.keyboard.colorScheme.bright        = {l.rgba(0x3e3c23ff)}
  patch.keyboard.colorScheme.surface       = {l.rgba(0x302e19ff)}
  patch.keyboard.colorScheme.surfaceC      = {l.rgba(0x2a2510ff)}

end

function patch.process(s)
  patch.keyboard:interpret(s)
  efx.tremolo.frequency    = l.remap(s.tilt.lp[1],-.3, .3, 0, 4, 'clamp')
  patch.pedal.masterVolume = l.remap(s.tilt.lp[2], .6,  0, 0, .7, 'clamp')
  patch.manOp.masterVolume = l.remap(s.tilt.lp[2], .1, .3, 0, .9, 'clamp')
  patch.pedal:processTouches(s.dt, s.touches)
  patch.manOp:processTouches(s.dt, s.touches)
  return s
end

function patch.draw(s)
  patch.keyboard:draw(s)
end

function patch.icon(time)
  local width = 0.6
  local off = math.cos(time) * 0.05
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