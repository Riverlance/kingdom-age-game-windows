_G.GameHotkeybars = { }



dofiles('ui')

local showHotkeybars = false
hotkeybars = { }



function GameHotkeybars.init()
  -- Alias
  GameHotkeybars.m = modules.ka_game_hotkeybars

  g_ui.importStyle('hotkeybars.otui')
  GameHotkeybars.initHotkeybars()

  connect(g_game, {
    onGameStart           = GameHotkeybars.online,
    onGameEnd             = GameHotkeybars.offline,
    onClientOptionChanged = GameHotkeybars.onClientOptionChanged,
  })

  connect(GameInterface.getMapPanel(), {
    onGeometryChange = GameHotkeybars.onMapPanelGeometryChange,
    onViewModeChange = GameHotkeybars.onViewModeChange,
    onZoomChange     = GameHotkeybars.onZoomChange,
  })

  if g_game.isOnline() then
    GameHotkeybars.loadHotkeybars()
  end
end

function GameHotkeybars.terminate()
  if g_game.isOnline() then
    GameHotkeybars.saveHotkeybars()
  end

  GameHotkeybars.deinitHotkeybars()

  disconnect(g_game, {
    onGameStart           = GameHotkeybars.online,
    onGameEnd             = GameHotkeybars.offline,
    onClientOptionChanged = GameHotkeybars.onClientOptionChanged,
  })

  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameHotkeybars.onMapPanelGeometryChange,
    onViewModeChange = GameHotkeybars.onViewModeChange,
    onZoomChange     = GameHotkeybars.onZoomChange,
  })

  _G.GameHotkeybars = nil
end

function GameHotkeybars.online()
  GameHotkeybars.updateHotkeybarPositions()
  GameHotkeybars.loadHotkeybars()

  if modules.game_console then
    connect(GameConsole.m.consolePanel, {
      onGeometryChange = GameHotkeybars.onGeometryChange
    })
  end
end

function GameHotkeybars.offline()
  if modules.game_console then
    disconnect(GameConsole.m.consolePanel, {
      onGeometryChange = GameHotkeybars.onGeometryChange
    })
  end
  GameHotkeybars.saveHotkeybars()
  GameHotkeybars.unloadHotkeybars()
end

-- Console geometry has changes
function GameHotkeybars.onGeometryChange(widget)
  GameHotkeybars.updateHotkeybarPositions()
end

function GameHotkeybars.onViewModeChange(mapWidget, viewMode, oldViewMode)
  GameHotkeybars.updateHotkeybarPositions()
end

function GameHotkeybars.onZoomChange(self, oldZoom, newZoom)
  if oldZoom == newZoom then
    return
  end

  GameHotkeybars.updateHotkeybarPositions()
end

function GameHotkeybars.onClientOptionChanged(key, value, force, wasClientSettingUp)
  GameHotkeybars.updateHotkeybarPositions()
end

-- Widget mapPanel geometry has changes
function GameHotkeybars.onMapPanelGeometryChange(mapWidget)
  GameHotkeybars.updateHotkeybarPositions()
end

function GameHotkeybars.updateLook()
  for i = 1, #hotkeybars do
    hotkeybars[i]:updateLook()
  end
end

-- Module game_hotkeys has changes
function GameHotkeybars.onUpdateHotkeys()
  GameHotkeybars.updateLook()
end

function GameHotkeybars.getHotkeyBars()
  return hotkeybars
end

-- Adjust positions according to viewmode and geometry
function GameHotkeybars.updateHotkeybarPositions()
  local mapWidget = GameInterface.getMapPanel()
  for alignment = 1, #hotkeybars do
    local tmpHotkeybar   = hotkeybars[alignment]
    -- local isFullViewMode = GameInterface.isViewModeFull()

    -- Horizontal

    if alignment == AnchorTop then
      addEvent(function() tmpHotkeybar:setMarginTop( GameInterface.m.topMenuButton:getHeight() + tmpHotkeybar.mapMargin ) end)

    elseif alignment == AnchorBottom then
      addEvent(function() tmpHotkeybar:setMarginBottom( GameInterface.m.chatButton:getHeight() + tmpHotkeybar.mapMargin + (GameInterface.m.gameExpBar:isOn() and GameInterface.m.gameExpBar:getHeight() or 0) ) end)

    -- Vertical

    elseif alignment == AnchorLeft then
      addEvent(function() tmpHotkeybar:setMarginLeft( GameInterface.m.leftPanelButton:getWidth() + tmpHotkeybar.mapMargin ) end)

    elseif alignment == AnchorRight then
      addEvent(function() tmpHotkeybar:setMarginRight( GameInterface.m.rightPanelButton:getWidth() + tmpHotkeybar.mapMargin ) end)
    end
  end
end

function GameHotkeybars.initHotkeybars()
  for i = AnchorTop, AnchorRight do
    local hotkeybar = g_ui.createWidget('Hotkeybar', GameInterface.getRootPanel())
    hotkeybar:setHotkeybarId(i)
    hotkeybar:setAlignment(i)
    hotkeybars[i] = hotkeybar
  end
end

function GameHotkeybars.deinitHotkeybars()
  for i = 1, #hotkeybars do
    hotkeybars[i]:destroy()
  end
end

function GameHotkeybars.saveHotkeybars()
  for i = 1, #hotkeybars do
    hotkeybars[i]:save()
  end
end

function GameHotkeybars.loadHotkeybars()
  for i = 1, #hotkeybars do
    hotkeybars[i]:load()
  end
  GameHotkeybars.updateDraggable(false)
end

function GameHotkeybars.unloadHotkeybars()
  for i = 1, #hotkeybars do
    hotkeybars[i]:unload()
  end
end

function GameHotkeybars.toggleHotkeybars(show)
  for i = 1, #hotkeybars do
    hotkeybars[i]:setVisible(show)
  end
end

function GameHotkeybars.updateDraggable(bool)
  for i = 1, #hotkeybars do
    hotkeybars[i]:updateDraggable(bool)
  end
end

function GameHotkeybars.onDisplay(show)
  showHotkeybars = show
  GameHotkeybars.toggleHotkeybars(show)
end

function GameHotkeybars.isHotkeybarsVisible()
  return showHotkeybars
end

function GameHotkeybars.setPowerIcon(keyCombo, enabled)
  if not modules.game_hotkeys then
    return
  end

  local view = GameHotkeys.getHotkey(keyCombo)
  if not view then
    return
  end

  local path = string.format('/images/ui/power/%d_%s', view.id, enabled and 'on' or 'off')

  for i = 1, #hotkeybars do
    local hotkeyWidget = hotkeybars[i]:getChildById(keyCombo)
    if hotkeyWidget then
      local powerWidget = hotkeyWidget:getChildById('power')
      if powerWidget then
        powerWidget:setImageSource(path)
      end
    end
  end
end

function GameHotkeybars.addPowerSendingHotkeyEffect(keyCombo, boostLevel)
  for i = 1, #hotkeybars do
    local hotkeyWidget = hotkeybars[i]:getChildById(keyCombo)
    if hotkeyWidget then
      local powerWidget = hotkeyWidget:getChildById('power')
      if powerWidget then
        local particle = g_ui.createWidget(string.format('PowerSendingParticlesBoost%d', boostLevel), powerWidget)
        particle:fill('parent')
        scheduleEvent(function() particle:destroy() end, 1000)
      end
    end
  end
end
