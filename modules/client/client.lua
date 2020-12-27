_G.Client = { }

local musicFilename = "/audios/startup"
local musicChannel = g_sounds.getChannel(AudioChannels.Music)
local loadingBox = nil
local isLoaded = false

playerSettingsPath = ""



function Client.init()
  -- Alias
  Client.m = modules.client

  connect(g_app, {
    onRun  = Client.startup,
    onExit = Client.exit
  })

  g_window.setMinimumSize({ width = 600, height = 480 })
  -- g_sounds.preload(musicFilename)

  -- initialize in fullscreen mode on mobile devices
  if g_window.getPlatformType() == "X11-EGL" then
    g_window.setFullscreen(true)
  else
    -- window size
    local size = { width = 800, height = 600 }
    size = g_settings.getSize('window-size', size)
    g_window.resize(size)

    -- window position, default is the screen center
    local displaySize = g_window.getDisplaySize()
    local defaultPos = { x = (displaySize.width - size.width) / 2, y = (displaySize.height - size.height) / 2 }
    local pos = g_settings.getPoint('window-pos', defaultPos)
    pos.x = math.max(pos.x, 0)
    pos.y = math.max(pos.y, 0)
    g_window.move(pos)

    -- window maximized?
    local maximized = g_settings.getBoolean('window-maximized', false)
    if maximized then
      g_window.maximize()
    end
  end

  g_window.setTitle(g_app.getName())
  g_window.setIcon('/images/client_icon')

  -- poll resize events
  g_window.poll()

  --g_keyboard.bindKeyDown('Ctrl+Shift+R', Client.reloadScripts)

  -- generate machine uuid, this is a security measure for storing passwords
  if not g_crypt.setMachineUUID(g_settings.get('uuid')) then
    g_settings.set('uuid', g_crypt.getMachineUUID())
    g_settings.save()
  end

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeOtclientSignal, Client.onRecvOtclientSignal)
end

function Client.terminate()
  disconnect(g_app, {
    onRun  = Client.startup,
    onExit = Client.exit
  })

  -- save window configs
  g_settings.set('window-size', g_window.getUnmaximizedSize())
  g_settings.set('window-pos', g_window.getUnmaximizedPos())
  g_settings.set('window-maximized', g_window.isMaximized())

  _G.Client = nil
end



function Client.startup()
  musicChannel:play(musicFilename, 1.0, -1, 7) -- Startup music

  connect(g_updater, {
    onUpdated = Client.loadFiles
  })
  connect(g_things, {
    onLoadDat = Client.onLoadFiles
  })
  connect(g_sprites, {
    onLoadSpr = Client.onLoadFiles
  })

  connect(g_game, {
    onGameStart = Client.onGameStart,
    onGameEnd   = Client.onGameEnd,
  })

  -- Check for startup errors
  if g_graphics.getRenderer():lower():match('gdi generic') then
    local errtitle = tr('Graphics card driver not detected')
    local errmsg = tr('No graphics card detected. Everything will be drawn using the CPU,\nthus the performance will be really bad.\nUpdate your graphics driver to have a better performance.')
    displayErrorBox(errtitle, errmsg)
  end
end

function Client.exit()
  disconnect(g_game, {
    onGameStart = Client.onGameStart,
    onGameEnd   = Client.onGameEnd,
  })

  disconnect(g_sprites, {
    onLoadSpr = Client.onLoadFiles
  })
  disconnect(g_things, {
    onLoadDat = Client.onLoadFiles
  })
  disconnect(g_updater, {
    onUpdated = Client.loadFiles
  })

  g_logger.info("Exiting application...")
end

function Client.onRecvOtclientSignal() -- From Server ProtocolGame::onRecvFirstMessage
  -- Nothing yet
end

function Client.onLoadFiles()
  if g_sprites.isLoaded() and g_things.isDatLoaded() then
    isLoaded = true
    ClientEnterGame.firstShow()
    if loadingBox then
      loadingBox:destroy()
      loadingBox = nil
    end
  end
end

function Client.onGameStart()
  ClientAudio.clearAudios()
end

function Client.onGameEnd()
  ClientAudio.clearAudios()
  musicChannel:play(musicFilename, 1.0, -1, 7) -- Startup music
end

function Client.loadFiles()
  disconnect(g_updater, {
    onUpdated = Client.loadFiles
  })

  loadingBox = displaySystemBox(tr('Loading'), tr('Loading files...'))

  local version = 1099
  g_game.setClientVersion(version)
  -- New limit of sprites
  g_game.enableFeature(GameSpritesU32) -- Automatically activated on 960+ protocol
  -- Alpha channel on sprites
  g_game.enableFeature(GameSpritesAlphaChannel)
  -- New limit of effects
  g_game.enableFeature(GameMagicEffectU16)

  scheduleEvent(function()
    local  path = resolvepath('/things/Kingdom Age')
    local errorMessage = ''
    if not g_things.loadDat(path) then
      errorMessage = errorMessage .. tr("Unable to load dat file, place a valid dat in '%s'", path) .. '\n'
    end
    if not g_sprites.loadSpr(path) then
      errorMessage = errorMessage .. tr("Unable to load spr file, place a valid spr in '%s'", path)
    end

    if errorMessage:len() > 0 then
      local messageBox = displayErrorBox(tr('Error'), errorMessage)
      addEvent(function() messageBox:raise() messageBox:focus() end)
      g_game.setClientVersion(0)
      g_game.setProtocolVersion(0)
    end
  end, 1)
end

function Client.isLoaded()
  return isLoaded
end

function Client.reloadScripts()
  g_textures.clearCache()
  g_modules.reloadModules()

  local script = '/' .. g_app.getCompactName() .. 'rc.lua'
  if g_resources.fileExists(script) then
    dofile(script)
  end

  local message = tr('All modules and scripts were reloaded.')

  if modules.game_textmessage then
    GameTextMessage.displayGameMessage(message)
  end

  print(message)
end



function Client.getPlayerSettings(fileName) -- ([fileName])
  if g_game.isOnline() then
    playerSettingsPath = string.format('/%s/%s', G.host:gsub("[%W]", "_"):lower(), g_game.getCharacterName():gsub("[%W]", "_"))
  end
  if not g_resources.makeDir(playerSettingsPath) then
    g_logger.error(string.format('Failed to load path \'%s\'', playerSettingsPath))
  end

  local playerSettingsFilePath = string.format('%s/%s.otml', playerSettingsPath, fileName or 'config')

  -- Create or load player settings file
  local file = g_configs.create(playerSettingsFilePath)
  if not file then
    g_logger.error(string.format('Failed to load file at \'%s\'', playerSettingsFilePath))
  end

  return file
end
