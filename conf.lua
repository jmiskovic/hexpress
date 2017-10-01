
function love.conf(t)
  local resolutions_16_9 = {
    [1] = {854, 480},
    [2] = {1024, 576},
    [3] = {1280, 720},  -- Redmi 3S
    [4] = {1280, 768},  -- Nexus4
    [5] = {1600, 900},
    [6] = {1920, 1080}, -- most common full screen
  }
  t.window.title = "Hextrument"
  t.window.width, t.window.height = unpack(resolutions_16_9[3])
  t.window.fullscreen = false
  t.window.vsync = false
end
