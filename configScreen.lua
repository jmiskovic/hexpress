local configScreen = {}


local callbacks = {
  'load',
  'draw',
  'update',
  'mousemoved',
  'mousepressed',
  'mousereleased',
  'keypressed',
}

local context = {}


function configScreen.enter()
  -- save Love2D callbacks so we can restore state on exiting the screen
  for _,name in ipairs(callbacks) do
    context[name] = love[name]
    love[name] = configScreen[name]
  end

  --context.load          = love.load
  --context.draw          = love.draw
  --context.update        = love.update
  --context.mousemoved    = love.mousemoved
  --context.mousepressed  = love.mousepressed
  --context.mousereleased = love.mousereleased
  --context.keypressed    = love.keypressed

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

end

function configScreen.keypressed(key)
    if key == 'escape' then
        configScreen.leave()
    end
end

return configScreen