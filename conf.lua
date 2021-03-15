
function love.conf(t)
  local resolutions = {
    [0] = {640, 360},
    [1] = {854, 480},
    [2] = {1024, 576},
    [3] = {1024, 768},  -- GalaxyTab
    [4] = {1280, 720},  -- Redmi 3S
    [5] = {1280, 768},  -- Nexus4
    [6] = {1600, 900},
    [7] = {1920, 1080}, -- most common desktop full screen
    [8] = {2960, 1440}, -- Samsung Galaxy S8
  }
  t.window.title = "Hexpress"
  t.window.width, t.window.height = unpack(resolutions[5])
  t.window.fullscreen = true
  t.window.resizable = false
  t.window.vsync = false
  t.audio.mic = true
end
