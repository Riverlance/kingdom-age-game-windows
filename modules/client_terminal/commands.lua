local function pcolored(text, color)
  color = color or 'white'
  ClientTerminal.addLine(tostring(text), color)
end

function draw_debug_boxes()
  g_ui.setDebugBoxesDrawing(not g_ui.isDrawingDebugBoxes())
end

function hide_map()
  if not modules.game_interface then
    return
  end
  GameInterface.getMapPanel():hide()
end

function show_map()
  if not modules.game_interface then
    return
  end
  GameInterface.getMapPanel():show()
end

function live_textures_reload()
  g_textures.liveReload()
end

function live_module_reload(name)
  if not name then
    pcolored('ERROR: missing module name', 'red')
    return
  end

  local module = g_modules.getModule(name)
  if not module then
    pcolored('ERROR: unable to find module ' .. name, 'red')
    return
  end

  if not module:isReloadble() then
    pcolored('ERROR: that module is not reloadable', 'red')
    return
  end

  if not module:canReload() then
    pcolored('ERROR: some other modules requires this module, cannot reload now', 'red')
    return
  end

  local files = {}
  local hasFile = false
  for _,file in pairs(g_resources.listDirectoryFiles('/' .. name)) do
    local filepath = '/' .. name .. '/' .. file
    local time = g_resources.getFileTime(filepath)
    if time > 0 then
      files[filepath] = time
      hasFile = true
    end
  end

  if not hasFile then
    pcolored('ERROR: unable to find any file for module', 'red')
    return
  end

  cycleEvent(function()
    for filepath,time in pairs(files) do
      local newtime = g_resources.getFileTime(filepath)
      if newtime > time then
        pcolored('Reloading ' .. name, 'green')
        ClientTerminal.flushLines()
        module:reload()
        files[filepath] = newtime

        if name == 'client_terminal' then
          ClientTerminal.show()
        end
        break
      end
    end
  end, 1000)
end

function live_sprites_reload()
  local files = {}
  for _,file in pairs(g_resources.listDirectoryFiles('/things')) do
    local filepath = '/things/' .. file
    local time = g_resources.getFileTime(filepath)
    if time > 0 then
      files[filepath] = time
      hasFile = true
    end
  end

  if not hasFile then
    pcolored('ERROR: unable to find things file for module', 'red')
    return
  end

  cycleEvent(function()
    for filepath,time in pairs(files) do
      local newtime = g_resources.getFileTime(filepath)
      if newtime > time then
        pcolored('Reloading sprites...', 'green')
        ClientTerminal.flushLines()
        -- if modules.game_things then
        --   GameThings.load()
        -- end
        files[filepath] = newtime

        if name == 'client_terminal' then
          ClientTerminal.show()
        end
        break
      end
    end
  end, 1000)
end

local pinging = false
local function pingBack(ping)
  if ping < 300 then color = 'green'
  elseif ping < 600 then color = 'yellow'
  else color = 'red' end
  pcolored(g_game.getWorldName() .. ' => ' .. ping .. ' ms', color)
end
function ping()
  if pinging then
    pcolored('Ping stopped.')
    g_game.setPingDelay(1000)
    disconnect(g_game, {
      onPingBack = pingBack
    })
  else
    if not g_game.isOnline() then
      pcolored('Ping command is only allowed when online.', 'red')
      return
    elseif not g_game.getFeature(GameClientPing) then
      pcolored('This server does not support ping.', 'red')
      return
    end

    pcolored('Starting ping...')
    g_game.setPingDelay(0)
    connect(g_game, {
      onPingBack = pingBack
    })
  end
  pinging = not pinging
end

function clear()
  ClientTerminal.clear()
end

function ls(path)
  path = path or '/'
  local files = g_resources.listDirectoryFiles(path)
  for k,v in pairs(files) do
    if g_resources.directoryExists(path .. v) then
      pcolored(path .. v, 'blue')
    else
      pcolored(path .. v)
    end
  end
end

function about_version()
  pcolored(g_app.getName() .. ' ' .. g_app.getVersion() .. '\n' ..
        'Rev  ' .. g_app.getBuildRevision() .. ' ('.. g_app.getBuildCommit() .. ')\n' ..
        'Built on ' .. g_app.getBuildDate())
end

function about_graphics()
  pcolored('Vendor ' .. g_graphics.getVendor() )
  pcolored('Renderer' .. g_graphics.getRenderer())
  pcolored('Version' .. g_graphics.getVersion())
end

function about_modules()
  for k,m in pairs(g_modules.getModules()) do
    local loadedtext
    if m:isLoaded() then
      pcolored(m:getName() .. ' => loaded', 'green')
    else
      pcolored(m:getName() .. ' => not loaded', 'red')
    end
  end
end
