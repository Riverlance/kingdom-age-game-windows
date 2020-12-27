_G.ClientOptions = { }



local optionsShortcut = 'Ctrl+Alt+O'
local audioShortcut = 'Ctrl+Alt+A'

local defaultOptions = {
  vsync = false,
  showFps = true,
  showPing = true,
  fullscreen = false,
  classicControl = false,
  smartWalk = false,
  dashWalk = false,
  autoChaseOverride = true,
  showStatusMessagesInConsole = true,
  showEventMessagesInConsole = true,
  showInfoMessagesInConsole = true,
  showTimestampsInConsole = true,
  showLevelsInConsole = true,
  showPrivateMessagesInConsole = true,
  showPrivateMessagesOnScreen = true,
  enabledLeftPanels = 1,
  enabledRightPanels = 1,
  panelsPriority = 0,
  showLeftPanel = true,
  showRightPanel = true,
  leftFirstPanelWidth = 5,
  rightFirstPanelWidth = 5,
  leftSecondPanelWidth = 5,
  rightSecondPanelWidth = 5,
  leftThirdPanelWidth = 5,
  rightThirdPanelWidth = 5,
  showTopMenu = true,
  showChat = true,
  gameScreenSize = 19,
  foregroundFrameRate = 61,
  backgroundFrameRate = 201,
  painterEngine = 0,
  enableAudio = true,
  enableMusic = true,
  enableSoundAmbient = true,
  enableSoundEffect = true,
  musicVolume = 100,
  soundAmbientVolume = 100,
  soundEffectVolume = 100,
  showNames = true,
  showLevel = true,
  showIcons = true,
  showHealth = true,
  showMana = true,
  showExpBar = true,
  showText = true,
  showHotkeybars = true,
  clearLootbarItemsOnEachDrop = true,
  showNpcDialogWindows = true,
  showMouseItemIcon = true,
  mouseItemIconOpacity = 30,
  dontStretchShrink = false,
  shaderFilter = ShaderFilter,
  viewMode = ViewModes[3].name,
  leftSticker = 'None',
  rightSticker = 'None',
  leftStickerOpacityScrollbar = 40,
  rightStickerOpacityScrollbar = 40,
  smoothWalk = true,
  walkingSensitivityScrollBar = 100,
  walkingRepeatDelayScrollBar = 200,
  bouncingKeys = true,
  bouncingKeysDelayScrollBar = 1000,
  turnDelay = 50,
  hotkeyDelay = 50,
  showMinimapExtraIcons = true,
}

local optionsWindow
local optionsButton
local optionsTabBar
local options = {}

local generalPanel
local controlPanel
local graphicPanel
local audioPanel
local displayPanel
local panelOptionsPanel
local consolePanel
local audioButton
local leftStickerComboBox
local rightStickerComboBox
local shaderFilterComboBox
local viewModeComboBox

local sidePanelsRadioGroup



local function setupGraphicsEngines()
  local enginesRadioGroup = UIRadioGroup.create()
  local ogl1 = graphicPanel:getChildById('opengl1')
  local ogl2 = graphicPanel:getChildById('opengl2')
  local dx9  = graphicPanel:getChildById('directx9')
  enginesRadioGroup:addWidget(ogl1)
  enginesRadioGroup:addWidget(ogl2)
  enginesRadioGroup:addWidget(dx9)

  if g_window.getPlatformType() == 'WIN32-EGL' then
    enginesRadioGroup:selectWidget(dx9)
    ogl1:setEnabled(false)
    ogl2:setEnabled(false)
    dx9:setEnabled(true)
  else
    ogl1:setEnabled(g_graphics.isPainterEngineAvailable(1))
    ogl2:setEnabled(g_graphics.isPainterEngineAvailable(2))
    dx9:setEnabled(false)
    if g_graphics.getPainterEngine() == 2 then
      enginesRadioGroup:selectWidget(ogl2)
    else
      enginesRadioGroup:selectWidget(ogl1)
    end

    if g_app.getOs() ~= 'windows' then
      dx9:hide()
    end
  end

  enginesRadioGroup.onSelectionChange = function(self, selected)
    if selected == ogl1 then
      ClientOptions.setOption('painterEngine', 1)
    elseif selected == ogl2 then
      ClientOptions.setOption('painterEngine', 2)
    end
  end

  if not g_graphics.canCacheBackbuffer() then
    graphicPanel:getChildById('foregroundFrameRate'):disable()
  end
end

local function setupSidePanelsPriority()
  local priorityLeftSide  = panelOptionsPanel:getChildById('panelsPriorityLeftSide')
  local priorityRightSide = panelOptionsPanel:getChildById('panelsPriorityRightSide')

  sidePanelsRadioGroup = UIRadioGroup.create()
  sidePanelsRadioGroup:addWidget(priorityLeftSide)
  sidePanelsRadioGroup:addWidget(priorityRightSide)

  sidePanelsRadioGroup.onSelectionChange = function(self, selected)
    if selected == priorityLeftSide then
      ClientOptions.setOption('panelsPriority', -1)
    elseif selected == priorityRightSide then
      ClientOptions.setOption('panelsPriority', 1)
    end
  end

  sidePanelsRadioGroup.update = function()
    local hasEnabledLeftPanels  = ClientOptions.getOption('enabledLeftPanels') > 0
    local hasEnabledRightPanels = ClientOptions.getOption('enabledRightPanels') > 0

    priorityLeftSide:setEnabled(hasEnabledLeftPanels)
    priorityRightSide:setEnabled(hasEnabledRightPanels)

    if not hasEnabledLeftPanels and not hasEnabledRightPanels then
      sidePanelsRadioGroup:clearSelected()
      ClientOptions.setOption('panelsPriority', 0)
    else
      local oldPanelsPriority = ClientOptions.getOption('panelsPriority')

      -- Priority order

      -- Has enabled right panels and (not chosen or chosen as right) or right is unique available
      if hasEnabledRightPanels and oldPanelsPriority > -1 or sidePanelsRadioGroup:isUniqueAvailableWidget(priorityRightSide) then
        sidePanelsRadioGroup:selectWidget(priorityRightSide)

      -- Has enabled left panels and (not chosen or chosen as left) or left is unique available
      elseif hasEnabledLeftPanels and oldPanelsPriority < 1 or sidePanelsRadioGroup:isUniqueAvailableWidget(priorityLeftSide) then
        sidePanelsRadioGroup:selectWidget(priorityLeftSide)
      end
    end
  end
end

local clientSettingUp = true
function ClientOptions.setup()
  setupGraphicsEngines()
  setupSidePanelsPriority()

  -- load options
  for k,v in pairs(defaultOptions) do
    if type(v) == 'boolean' then
      ClientOptions.setOption(k, g_settings.getBoolean(k), true)
    elseif type(v) == 'number' then
      ClientOptions.setOption(k, g_settings.getNumber(k), true)
    elseif type(v) == 'string' then
      ClientOptions.setOption(k, g_settings.getString(k), true)
    elseif k == "rightStickerComboBox" or k == "leftStickerComboBox" then
      ClientOptions.setOption(k, g_settings.get(k), true)
    end
  end

  clientSettingUp = false
end

function ClientOptions.init()
  -- Alias
  ClientOptions.m = modules.client_options

  for k,v in pairs(defaultOptions) do
    g_settings.setDefault(k, v)
    options[k] = v
  end

  optionsWindow = g_ui.displayUI('options')
  optionsWindow:hide()

  optionsTabBar = optionsWindow:getChildById('optionsTabBar')
  optionsTabBar:setContentWidget(optionsWindow:getChildById('optionsTabContent'))

  g_keyboard.bindKeyDown('Ctrl+Shift+F', function() ClientOptions.toggleOption('fullscreen') end)

  generalPanel      = g_ui.loadUI('game')
  controlPanel      = g_ui.loadUI('control')
  graphicPanel      = g_ui.loadUI('graphic')
  audioPanel        = g_ui.loadUI('audio')
  displayPanel      = g_ui.loadUI('display')
  panelOptionsPanel = g_ui.loadUI('panel')
  consolePanel      = g_ui.loadUI('console')
  optionsTabBar:addTab(tr('Game'), generalPanel, '/images/ui/options/game')
  optionsTabBar:addTab(tr('Control'), controlPanel, '/images/ui/options/control')
  optionsTabBar:addTab(tr('Graphic'), graphicPanel, '/images/ui/options/graphic')
  optionsTabBar:addTab(tr('Audio'), audioPanel, '/images/ui/options/audio')
  optionsTabBar:addTab(tr('Display'), displayPanel, '/images/ui/options/display')
  optionsTabBar:addTab(tr('Panel'), panelOptionsPanel, '/images/ui/options/panel')
  optionsTabBar:addTab(tr('Console'), consolePanel, '/images/ui/options/console')

  -- Shader filters
  shaderFilterComboBox = graphicPanel:getChildById('shaderFilterComboBox')
  if shaderFilterComboBox then
    for _, shaderFilter in ipairs(MapShaders) do
      if shaderFilter.isFilter then
        shaderFilterComboBox:addOption(shaderFilter.name)
      end
    end
    shaderFilterComboBox.onOptionChange = ClientOptions.setShaderFilter

    -- Select default shader
    local shaderFilter = g_settings.get(shaderFilterComboBox:getId(), defaultOptions.shaderFilter)
    shaderFilterComboBox:setOption(shaderFilter)
  end

  -- View mode combobox
  viewModeComboBox = graphicPanel:getChildById('viewModeComboBox')
  if viewModeComboBox then
    for k = 0, #ViewModes do
      viewModeComboBox:addOption(ViewModes[k].name)
    end
    viewModeComboBox.onOptionChange = ClientOptions.setViewMode

    -- Select default view mode
    local viewMode = g_settings.get(viewModeComboBox:getId(), defaultOptions.viewMode)
    viewModeComboBox:setOption(viewMode)
  end

  -- Mouse item icon example
  local showMouseItemIcon = displayPanel:getChildById('showMouseItemIcon')
  showMouseItemIcon.onHoverChange = function (self, hovered)
    if hovered then
      g_mouseicon.display(3585, ClientOptions.getOption('mouseItemIconOpacity') / 100, nil, 7)
    else
      g_mouseicon.hide()
    end
  end
  local mouseItemIconOpacity = displayPanel:getChildById('mouseItemIconOpacity')
  mouseItemIconOpacity.onHoverChange = showMouseItemIcon.onHoverChange

  -- Sticker combobox
  leftStickerComboBox = panelOptionsPanel:getChildById('leftStickerComboBox')
  rightStickerComboBox = panelOptionsPanel:getChildById('rightStickerComboBox')
  if leftStickerComboBox and rightStickerComboBox then
    for _, sticker in ipairs(PanelStickers) do
      leftStickerComboBox:addOption(sticker.opt)
      rightStickerComboBox:addOption(sticker.opt)
    end
    leftStickerComboBox.onOptionChange = ClientOptions.setSticker
    rightStickerComboBox.onOptionChange = ClientOptions.setSticker

    addEvent(ClientOptions.updateStickers, 500)
  end

  optionsButton = ClientTopMenu.addLeftButton('optionsButton', tr('Options') .. string.format(' (%s)', optionsShortcut), '/images/ui/top_menu/options', ClientOptions.toggle)
  g_keyboard.bindKeyDown(optionsShortcut, ClientOptions.toggle)
  audioButton = ClientTopMenu.addLeftButton('audioButton', tr('Audio') .. string.format(' (%s)', audioShortcut), '/images/ui/top_menu/audio', function() ClientOptions.toggleOption('enableAudio') end)
  g_keyboard.bindKeyDown(audioShortcut, function() ClientOptions.toggleOption('enableAudio') end)

  addEvent(function() ClientOptions.setup() end)
end

function ClientOptions.terminate()
  g_keyboard.unbindKeyDown(optionsShortcut)
  g_keyboard.unbindKeyDown(audioShortcut)
  g_keyboard.unbindKeyDown('Ctrl+Shift+F')
  optionsWindow:destroy()
  optionsButton:destroy()
  audioButton:destroy()

  _G.ClientOptions = nil
end

function ClientOptions.toggle()
  if optionsWindow:isVisible() then
    ClientOptions.hide()
  else
    ClientOptions.show()
  end
end

function ClientOptions.show()
  optionsWindow:show()
  optionsWindow:raise()
  optionsWindow:focus()
  optionsButton:setOn(true)
end

function ClientOptions.hide()
  optionsWindow:hide()
  optionsButton:setOn(false)
end

function ClientOptions.toggleOption(key)
  ClientOptions.setOption(key, not ClientOptions.getOption(key))
end

function ClientOptions.updateOption(key) -- Execute functions within its option
  local value = ClientOptions.getOption(key)
  if value == nil then
    return false
  end
  ClientOptions.setOption(key, value, true)
  return true
end

function ClientOptions.setOption(key, value, force)
  if not force and ClientOptions.getOption(key) == value then
    return
  end
  local wasClientSettingUp = clientSettingUp

  if key == 'vsync' then
    g_window.setVerticalSync(value)

  elseif key == 'showFps' then
    ClientTopMenu.setFpsVisible(value)

  elseif key == 'showPing' then
    ClientTopMenu.setPingVisible(value)

  elseif key == 'fullscreen' then
    g_window.setFullscreen(value)

  elseif key == 'enableAudio' then
    g_sounds.setEnabled(value)
    g_sounds.getChannel(AudioChannels.Music):setEnabled(value and ClientOptions.getOption('enableMusic'))
    g_sounds.getChannel(AudioChannels.Ambient):setEnabled(value and ClientOptions.getOption('enableSoundAmbient'))
    g_sounds.getChannel(AudioChannels.Effect):setEnabled(value and ClientOptions.getOption('enableSoundEffect'))
    if value then
      audioButton:setIcon('/images/ui/top_menu/audio')
      audioButton:setOn(true)
    else
      audioButton:setIcon('/images/ui/top_menu/audio_mute')
      audioButton:setOn(false)
    end

  elseif key == 'enableMusic' then
    g_sounds.getChannel(AudioChannels.Music):setEnabled(ClientOptions.getOption('enableAudio') and value)

  elseif key == 'musicVolume' then
    ClientAudio.setMusicVolume(value / 100)

  elseif key == 'enableSoundAmbient' then
    g_sounds.getChannel(AudioChannels.Ambient):setEnabled(ClientOptions.getOption('enableAudio') and value)

  elseif key == 'soundAmbientVolume' then
    ClientAudio.setAmbientVolume(value / 100)

  elseif key == 'enableSoundEffect' then
    g_sounds.getChannel(AudioChannels.Effect):setEnabled(ClientOptions.getOption('enableAudio') and value)

  elseif key == 'soundEffectVolume' then
    ClientAudio.setEffectVolume(value / 100)

  elseif modules.game_interface and key == 'enabledLeftPanels' then
    addEvent(function()
      local hasEnabled = value > 0
      if not wasClientSettingUp then
        sidePanelsRadioGroup.update()
      end

      GameInterface.setLeftPanels()
      if hasEnabled then -- Force left panel to appear
        ClientOptions.setOption('showLeftPanel', true)
      end
      GameInterface.moveHiddenPanelMiniWindows()

      GameInterface.m.leftPanelButton:setVisible(hasEnabled)

      panelOptionsPanel:getChildById('leftFirstPanelWidthLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftFirstPanelWidth'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftSecondPanelWidthLabel'):setEnabled(value >= 2)
      panelOptionsPanel:getChildById('leftSecondPanelWidth'):setEnabled(value >= 2)
      panelOptionsPanel:getChildById('leftThirdPanelWidthLabel'):setEnabled(value >= 3)
      panelOptionsPanel:getChildById('leftThirdPanelWidth'):setEnabled(value >= 3)

      panelOptionsPanel:getChildById('leftStickerLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftStickerComboBox'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftStickerOpacityLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('leftStickerOpacityScrollbar'):setEnabled(value >= 1)
    end)

  elseif modules.game_interface and key == 'enabledRightPanels' then
    addEvent(function()
      local hasEnabled = value > 0
      if not wasClientSettingUp then
        sidePanelsRadioGroup.update()
      end

      GameInterface.setRightPanels()
      if hasEnabled then -- Force right panel to appear
        ClientOptions.setOption('showRightPanel', true)
      end
      GameInterface.moveHiddenPanelMiniWindows()

      GameInterface.m.rightPanelButton:setVisible(hasEnabled)

      panelOptionsPanel:getChildById('rightFirstPanelWidthLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightFirstPanelWidth'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightSecondPanelWidthLabel'):setEnabled(value >= 2)
      panelOptionsPanel:getChildById('rightSecondPanelWidth'):setEnabled(value >= 2)
      panelOptionsPanel:getChildById('rightThirdPanelWidthLabel'):setEnabled(value >= 3)
      panelOptionsPanel:getChildById('rightThirdPanelWidth'):setEnabled(value >= 3)

      panelOptionsPanel:getChildById('rightStickerLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightStickerComboBox'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightStickerOpacityLabel'):setEnabled(value >= 1)
      panelOptionsPanel:getChildById('rightStickerOpacityScrollbar'):setEnabled(value >= 1)
    end)

  elseif modules.game_interface and key == 'panelsPriority' then
    addEvent(function()
      if wasClientSettingUp then
        sidePanelsRadioGroup.update()
      end
      GameInterface.setupPanels()
    end)

  elseif modules.game_interface and key == 'showLeftPanel' then
    local enabledLeftPanels = ClientOptions.getOption('enabledLeftPanels')
    if enabledLeftPanels < 1 then
      return
    end
    GameInterface.setLeftPanels(value)

  elseif modules.game_interface and key == 'showRightPanel' then
    local enabledRightPanels = ClientOptions.getOption('enabledRightPanels')
    if enabledRightPanels < 1 then
      return
    end
    GameInterface.setRightPanels(value)

  elseif modules.game_interface and table.contains({ 'leftFirstPanelWidth', 'rightFirstPanelWidth', 'leftSecondPanelWidth', 'rightSecondPanelWidth', 'leftThirdPanelWidth', 'rightThirdPanelWidth' }, key) then
    local width = value * 34 + 19 -- Slots width * slot size + minimum width

    if key == 'leftFirstPanelWidth' and GameInterface.m.gameLeftFirstPanel:isVisible() then
      GameInterface.m.gameLeftFirstPanel:setWidth(width)
    elseif key == 'rightFirstPanelWidth' and GameInterface.m.gameRightFirstPanel:isVisible() then
      GameInterface.m.gameRightFirstPanel:setWidth(width)

    elseif key == 'leftSecondPanelWidth' and GameInterface.m.gameLeftSecondPanel:isVisible() then
      GameInterface.m.gameLeftSecondPanel:setWidth(width)
    elseif key == 'rightSecondPanelWidth' and GameInterface.m.gameRightSecondPanel:isVisible() then
      GameInterface.m.gameRightSecondPanel:setWidth(width)

    elseif key == 'leftThirdPanelWidth' and GameInterface.m.gameLeftThirdPanel:isVisible() then
      GameInterface.m.gameLeftThirdPanel:setWidth(width)
    elseif key == 'rightThirdPanelWidth' and GameInterface.m.gameRightThirdPanel:isVisible() then
      GameInterface.m.gameRightThirdPanel:setWidth(width)
    end

  elseif modules.game_interface and key == 'showTopMenu' then
    ClientTopMenu.getTopMenu():setVisible(value)
    GameInterface.getTopMenuButton():setOn(value)

  elseif modules.game_interface and key == 'showChat' then
    GameInterface.getBottomPanel():setVisible(value)
    GameInterface.getSplitter():setVisible(value)
    GameInterface.getChatButton():setOn(value)

  elseif modules.game_interface and key == 'gameScreenSize' then
    GameInterface.getMapPanel():setZoom( value % 2 == 0 and value + 1 or value )

  elseif key == 'backgroundFrameRate' then
    g_app.setBackgroundPaneMaxFps( value > 0 and value < 201 and value or 0 )

  elseif key == 'foregroundFrameRate' then
    g_app.setForegroundPaneMaxFps( value > 0 and value < 61 and value or 0 )

  elseif key == 'painterEngine' then
    g_graphics.selectPainterEngine(value)

  elseif modules.game_interface and key == 'showNames' then
    GameInterface.getMapPanel():setDrawNames(value)

  elseif modules.game_interface and key == 'showLevel' then
    GameInterface.getMapPanel():setDrawLevels(value)

  elseif modules.game_interface and key == 'showIcons' then
    GameInterface.getMapPanel():setDrawIcons(value)

  elseif modules.game_interface and key == 'showHealth' then
    GameInterface.getMapPanel():setDrawHealthBars(value)

  elseif modules.game_interface and key == 'showMana' then
    GameInterface.getMapPanel():setDrawManaBar(value)

  elseif key == 'showExpBar' then
    if not modules.ka_game_ui then
      return
    end
    GameUIExpBar.setExpBar(value)

  elseif modules.game_interface and key == 'showText' then
    GameInterface.getMapPanel():setDrawTexts(value)

  elseif key == 'showHotkeybars' then
    if not modules.ka_game_hotkeybars then
      return
    end
    GameHotkeybars.onDisplay(value)

  elseif key == 'showNpcDialogWindows' then
    g_game.setNpcDialogWindows(value)

  elseif modules.game_interface and key == 'dontStretchShrink' then
    addEvent(function() GameInterface.updateStretchShrink() end)

  elseif modules.game_interface and key == 'leftStickerOpacityScrollbar' then
    local leftStickerWidget = GameInterface.getLeftFirstPanel():getChildById('gameLeftPanelSticker')
    if not leftStickerWidget then
      return
    end

    local _value = math.ceil(value * 2.55)
    local alpha  = string.format('%s%x', _value < 16 and '0' or '', _value)
    leftStickerWidget:setImageColor(tocolor('#FFFFFF' .. alpha))

  elseif modules.game_interface and key == 'rightStickerOpacityScrollbar' then
    local rightStickerWidget = GameInterface.getRightFirstPanel():getChildById('gameRightPanelSticker')
    if not rightStickerWidget then
      return
    end

    local _value = math.ceil(value * 2.55)
    local alpha  = string.format('%s%x', _value < 16 and '0' or '', _value)
    rightStickerWidget:setImageColor(tocolor('#FFFFFF' .. alpha))

  elseif key == "shaderFilterComboBox" then
    shaderFilterComboBox:setOption(value)

  elseif key == "viewModeComboBox" then
    viewModeComboBox:setOption(value)

  elseif key == "leftStickerComboBox" then
    leftStickerComboBox:setOption(value)

  elseif key == "rightStickerComboBox" then
    rightStickerComboBox:setOption(value)

  elseif modules.game_interface and key == 'walkingRepeatDelayScrollBar' then
    GameInterface.setWalkingRepeatDelay(value)

  elseif key == 'smoothWalk' then
    controlPanel:getChildById('walkingSensitivityScrollBar'):setEnabled(value)
    controlPanel:getChildById('walkingRepeatDelayScrollBar'):setEnabled(value)

  elseif key == 'bouncingKeys' then
    controlPanel:getChildById('bouncingKeysDelayScrollBar'):setEnabled(value)

  elseif key == 'showMinimapExtraIcons' then
    if not modules.game_minimap then
      return
    end

    local minimapWidget = GameMinimap.getMinimapWidget()
    minimapWidget:setAlternativeWidgetsVisible(value)

    GameMinimap.m.extraIconsButton:setOn(value)
  end

  -- change value for keybind updates
  for _,panel in pairs(optionsTabBar:getTabsPanel()) do
    local widget = panel:recursiveGetChildById(key)
    if widget then
      if widget:getStyle().__class == 'UICheckBox' then
        widget:setChecked(value)
      elseif widget:getStyle().__class == 'UIScrollBar' then
        widget:setValue(value)
      end
      break
    end
  end

  g_settings.set(key, value)
  options[key] = value

  signalcall(g_game.onClientOptionChanged, key, value, force, wasClientSettingUp)
end

function ClientOptions.getOption(key)
  return options[key]
end

function ClientOptions.addTab(name, panel, icon)
  optionsTabBar:addTab(name, panel, icon)
end

function ClientOptions.addButton(name, func, icon)
  optionsTabBar:addButton(name, func, icon)
end



-- Panel Stickers

function ClientOptions.updateStickers()
  -- Left panel
  local leftStickerWidget = GameInterface.getLeftFirstPanel():getChildById('gameLeftPanelSticker')
  if leftStickerWidget then
    local value = g_settings.get(leftStickerComboBox:getId())
    value = type(value) == "string" and value ~= "" and value or defaultOptions.leftSticker

    leftStickerComboBox:setOption(value) -- Make sure combobox has same as value at g_settings
    leftStickerComboBox.tooltipAddons = value ~= defaultOptions.leftSticker and { {{ image = PanelStickers[value], align = AlignCenter }} } or nil
    leftStickerWidget:setImageSource(PanelStickers[value])
  end

  -- Right panel
  local rightStickerWidget = GameInterface.getRightFirstPanel():getChildById('gameRightPanelSticker')
  if rightStickerWidget then
    local value = g_settings.get(rightStickerComboBox:getId())
    value = type(value) == "string" and value ~= "" and value or defaultOptions.rightSticker

    rightStickerComboBox:setOption(value) -- Make sure combobox has same as value at g_settings
    rightStickerComboBox.tooltipAddons = value ~= defaultOptions.rightSticker and { {{ image = PanelStickers[value], align = AlignCenter }} } or nil
    rightStickerWidget:setImageSource(PanelStickers[value])
  end
end

function ClientOptions.setSticker(comboBox, opt)
  g_settings.set(comboBox:getId(), opt)
  ClientOptions.setOption(comboBox:getId(), opt)
  ClientOptions.updateStickers()
end



-- Shader Filter

function ClientOptions.setShaderFilter(comboBox, opt)
  g_settings.set(comboBox:getId(), opt)
  ClientOptions.setOption(comboBox:getId(), opt)
  setMapShader(opt)
end

-- View Mode

function ClientOptions.setViewMode(comboBox, opt)
  g_settings.set(comboBox:getId(), opt)
  ClientOptions.setOption(comboBox:getId(), opt)
  if modules.game_interface then
    local viewModeId = 0
    for k = 0, #ViewModes do
      if opt == ViewModes[k].name then
        viewModeId = k
        break
      end
    end
    GameInterface.setupViewMode(viewModeId)
  end
end
