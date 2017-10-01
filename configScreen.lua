local configScreen = {}

local suit = require('SUIT')

local fontSetting = {font=love.graphics.newFont(22)}


local context = {}
local callbacks = {
  'load',
  'draw',
  'update',
  'mousemoved',
  'mousepressed',
  'mousereleased',
  'keypressed',
  'touchpressed',
  'touchmoved',
  'touchreleased',
}

configScreen.A = {value = 0.1, min = 0, max = 0.5, unit='s'} -- attack
configScreen.D = {value = 0.1, min = 0, max = 0.5, unit='s'} -- decay
configScreen.S = {value = 0.7, min = 0, max = 1.0, unit='x'}  -- sustain
configScreen.R = {value = 0.2, min = 0, max = 0.5, unit='s'} -- release

function configScreen.enter()
  -- save Love2D callbacks so we can restore state on exiting the screen
  for _,name in ipairs(callbacks) do
    context[name] = love[name]
    love[name] = configScreen[name]
  end

  love.draw       = configScreen.draw
  love.keypressed = configScreen.keypressed

end

function configScreen.leave()
  -- restore callbacks to previous state to release control
  for _,name in ipairs(callbacks) do
    love[name] = context[name]
  end
end

function configScreen.draw()
  suit.draw()
end

function configScreen.keypressed(key)
    if key == 'escape' then
        configScreen.leave()
        love.load()
    end
end

function configScreen.update(dt)
  for i,e in ipairs({'A', 'D', 'S', 'R'}) do
    suit.Slider(configScreen[e], 50,  i * 100 - 15, 500, 60)
    suit.Label(e, fontSetting, 20, i*100)
    local value = string.format('%1.1f %s', configScreen[e].value, configScreen[e].unit)
    suit.Label(value, fontSetting, 575, i*100)
  end
end

return configScreen