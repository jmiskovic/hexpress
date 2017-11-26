
function love.conf(t)
  local resolutions = {
    [0] = {640, 360},
    [1] = {854, 480},
    [2] = {1024, 576},
    [3] = {1280, 720},  -- Redmi 3S
    [4] = {1280, 768},  -- Nexus4
    [5] = {1600, 900},
    [6] = {1920, 1080}, -- most common desktop full screen
    [7] = {2960, 1440}, -- Samsung Galaxy S8
  }
  t.window.title = "Hextrument"
  t.window.width, t.window.height = unpack(resolutions[6])
  t.window.fullscreen = false
  t.window.resizable = true
  t.window.vsync = false
end
