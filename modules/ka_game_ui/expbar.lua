_G.GameUIExpBar = { }



function GameUIExpBar.init()
  -- Alias
  GameUIExpBar.m = modules.ka_game_ui

  connect(g_game, {
    onClientOptionChanged = GameUIExpBar.onClientOptionChanged,
  })

  connect(GameInterface.getMapPanel(), {
    onGeometryChange = GameUIExpBar.onGeometryChange,
    onViewModeChange = GameUIExpBar.onViewModeChange,
    onZoomChange     = GameUIExpBar.onZoomChange,
  })

  connect(LocalPlayer, {
    onLevelChange = GameUIExpBar.onLevelChange,
  })

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    GameUIExpBar.onLevelChange(localPlayer, localPlayer:getLevel(), localPlayer:getLevelPercent())
  end
end

function GameUIExpBar.terminate()
  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameUIExpBar.onGeometryChange,
    onViewModeChange = GameUIExpBar.onViewModeChange,
    onZoomChange     = GameUIExpBar.onZoomChange,
  })

  disconnect(LocalPlayer, {
    onLevelChange = GameUIExpBar.onLevelChange,
  })

  disconnect(g_game, {
    onClientOptionChanged = GameUIExpBar.onClientOptionChanged,
  })

  _G.GameUIExpBar = nil
end

function GameUIExpBar.updateGameExpBarPercent(percent)
  if not GameInterface.m.gameExpBar:isOn() then
    return
  end

  local localPlayer = g_game.getLocalPlayer()
  if not percent and not localPlayer then
    return
  end

  percent = percent or localPlayer:getLevelPercent()

  local emptyGameExpBar = GameInterface.m.gameExpBar:getChildById('empty')
  local fullGameExpBar  = GameInterface.m.gameExpBar:getChildById('full')
  fullGameExpBar:setWidth(emptyGameExpBar:getWidth() * (percent / 100))
end

function GameUIExpBar.updateGameExpBarPos()
  if not GameInterface.m.gameExpBar:isOn() then
    return
  end

  local horizontalMargin = 0

  if GameInterface.isViewModeFull() or not GameInterface.getSplitter():isVisible() then
    horizontalMargin = 4
  end

  GameInterface.m.gameExpBar:setMarginLeft(horizontalMargin)
  GameInterface.m.gameExpBar:setMarginRight(horizontalMargin)

  GameUIExpBar.updateGameExpBarPercent()
end

function GameUIExpBar.updateExpBar()
  GameUIExpBar.updateGameExpBarPercent()
  GameUIExpBar.updateGameExpBarPos()
end

function GameUIExpBar.onGeometryChange()
  addEvent(function() GameUIExpBar.updateExpBar() end)
end

function GameUIExpBar.onViewModeChange(mapWidget, newMode, oldMode)
  addEvent(function() GameUIExpBar.updateExpBar() end)
end

function GameUIExpBar.onClientOptionChanged(key, value, force, wasClientSettingUp)
  addEvent(function() GameUIExpBar.updateExpBar() end)
end

function GameUIExpBar.onZoomChange(self, oldZoom, newZoom)
  if oldZoom == newZoom then
    return
  end
  addEvent(function() GameUIExpBar.updateExpBar() end)
end

function GameUIExpBar.onLevelChange(localPlayer, level, levelPercent, oldLevel, oldLevelPercent)
  GameInterface.m.gameExpBar:setTooltip(getExperienceTooltipText(localPlayer, level, levelPercent))
  GameUIExpBar.updateGameExpBarPercent(levelPercent)
end

function GameUIExpBar.setExpBar(enable)
  local isOn = GameInterface.m.gameExpBar:isOn()

  -- Enable bar
  if not isOn and enable then
    GameInterface.m.gameExpBar:setOn(true)
    GameUIExpBar.updateExpBar()
  -- Disable bar
  elseif isOn and not enable then
    GameInterface.m.gameExpBar:setOn(false)
    GameUIExpBar.updateExpBar()
  end
end
