_G.GameInterface = { }



WALK_STEPS_RETRY = 10

gameRootPanel = nil
gameMapPanel = nil
gameRightFirstPanel = nil
gameRightSecondPanel = nil
gameRightThirdPanel = nil
gameLeftFirstPanel = nil
gameLeftSecondPanel = nil
gameLeftThirdPanel = nil
gameRightFirstPanelContainer = nil
gameRightSecondPanelContainer = nil
gameRightThirdPanelContainer = nil
gameLeftFirstPanelContainer = nil
gameLeftSecondPanelContainer = nil
gameLeftThirdPanelContainer = nil
gameBottomPanel = nil
logoutButton = nil
mouseGrabberWidget = nil
countWindow = nil
logoutWindow = nil
exitWindow = nil
bottomSplitter = nil
gameExpBar = nil
leftPanelButton = nil
rightPanelButton = nil
topMenuButton = nil
chatButton = nil
currentViewMode = 0
smartWalkDirs = {}
smartWalkDir = nil
walkFunction = nil
hookedMenuOptions = {}
lastDirTime = g_clock.millis()
gamePanels = {}
gamePanelsContainer = {}

-- List of panels, even if panelsPriority is not set
local _gamePanels = {}
local _gamePanelsContainer = {}

function GameInterface.init()
  -- Alias
  GameInterface.m = modules.game_interface

  g_ui.importStyle('styles/countwindow')

  rootWidget:setImageSource('/images/ui/_background/panel_root')

  gameRootPanel = g_ui.displayUI('interface')
  gameRootPanel:hide()
  gameRootPanel:lower()

  mouseGrabberWidget = gameRootPanel:getChildById('mouseGrabber')

  bottomSplitter = gameRootPanel:getChildById('bottomSplitter')
  gameExpBar = gameRootPanel:getChildById('gameExpBar')
  leftPanelButton = gameRootPanel:getChildById('leftPanelButton')
  rightPanelButton = gameRootPanel:getChildById('rightPanelButton')
  topMenuButton = gameRootPanel:getChildById('topMenuButton')
  chatButton = gameRootPanel:getChildById('chatButton')
  gameMapPanel = gameRootPanel:getChildById('gameMapPanel')
  gameRightFirstPanel = gameRootPanel:getChildById('gameRightFirstPanel')
  gameRightSecondPanel = gameRootPanel:getChildById('gameRightSecondPanel')
  gameRightThirdPanel = gameRootPanel:getChildById('gameRightThirdPanel')
  gameLeftFirstPanel = gameRootPanel:getChildById('gameLeftFirstPanel')
  gameLeftSecondPanel = gameRootPanel:getChildById('gameLeftSecondPanel')
  gameLeftThirdPanel = gameRootPanel:getChildById('gameLeftThirdPanel')
  gameRightFirstPanelContainer = gameRightFirstPanel:getChildById('gameRightFirstPanelContainer')
  gameRightSecondPanelContainer = gameRightSecondPanel:getChildById('gameRightSecondPanelContainer')
  gameRightThirdPanelContainer = gameRightThirdPanel:getChildById('gameRightThirdPanelContainer')
  gameLeftFirstPanelContainer = gameLeftFirstPanel:getChildById('gameLeftFirstPanelContainer')
  gameLeftSecondPanelContainer = gameLeftSecondPanel:getChildById('gameLeftSecondPanelContainer')
  gameLeftThirdPanelContainer = gameLeftThirdPanel:getChildById('gameLeftThirdPanelContainer')
  gameBottomPanel = gameRootPanel:getChildById('gameBottomPanel')

  _gamePanels = {
    gameRightFirstPanel,
    gameLeftFirstPanel,
    gameRightSecondPanel,
    gameLeftSecondPanel,
    gameRightThirdPanel,
    gameLeftThirdPanel,
  }
  _gamePanelsContainer = {
    gameRightFirstPanelContainer,
    gameLeftFirstPanelContainer,
    gameRightSecondPanelContainer,
    gameLeftSecondPanelContainer,
    gameRightThirdPanelContainer,
    gameLeftThirdPanelContainer,
  }

  GameInterface.setupPanels()

  -- Call load AFTER game window has been created and
  -- resized to a stable state, otherwise the saved
  -- settings can get overridden by false onGeometryChange
  -- events
  connect(g_app, {
    onRun  = GameInterface.load,
    onExit = GameInterface.save,
  })

  connect(g_game, {
    onGameStart   = GameInterface.onGameStart,
    onGameEnd     = GameInterface.onGameEnd,
    onLoginAdvice = GameInterface.onLoginAdvice,
  }, true)

  connect(gameRootPanel, {
    onGeometryChange = GameInterface.updateStretchShrink,
    onFocusChange    = GameInterface.stopSmartWalk,
  })

  connect(mouseGrabberWidget, {
    onMouseRelease = GameInterface.onMouseGrabberRelease,
  })

  for i = 1, #_gamePanelsContainer do
    connect(_gamePanelsContainer[i], {
      onFitAll = GameInterface.fitAllPanelChildren,
    })
  end

  connect(bottomSplitter, {
    onDoubleClick = GameInterface.onSplitterDoubleClick,
  })

  logoutButton = ClientTopMenu.addLeftButton('logoutButton', tr('Exit'), '/images/ui/top_menu/logout', GameInterface.tryLogout, true)

  GameInterface.bindKeys()

  if g_game.isOnline() then
    GameInterface.show()
  end
end

function GameInterface.bindWalkKey(key, dir)
  g_keyboard.bindKeyDown(key, function() GameInterface.changeWalkDir(dir) end, gameRootPanel, true)
  g_keyboard.bindKeyUp(key, function() GameInterface.changeWalkDir(dir, true) end, gameRootPanel, true)
  g_keyboard.bindKeyPress(key, function() GameInterface.smartWalk(dir) end, gameRootPanel)
end

function GameInterface.unbindWalkKey(key)
  g_keyboard.unbindKeyDown(key, gameRootPanel)
  g_keyboard.unbindKeyUp(key, gameRootPanel)
  g_keyboard.unbindKeyPress(key, gameRootPanel)
end

function GameInterface.bindTurnKey(key, dir)
  local function callback(widget, code, repeatTicks)
    if g_clock.millis() - lastDirTime >= ClientOptions.getOption('turnDelay') then
      g_game.turn(dir)
      GameInterface.changeWalkDir(dir)
      lastDirTime = g_clock.millis()
    end
  end
  g_keyboard.bindKeyPress(key, callback, gameRootPanel)
end

function GameInterface.bindKeys()
  gameRootPanel:setAutoRepeatDelay(200)

  GameInterface.bindWalkKey('Up', North)
  GameInterface.bindWalkKey('Right', East)
  GameInterface.bindWalkKey('Down', South)
  GameInterface.bindWalkKey('Left', West)
  GameInterface.bindWalkKey('Numpad8', North)
  GameInterface.bindWalkKey('Numpad9', NorthEast)
  GameInterface.bindWalkKey('Numpad6', East)
  GameInterface.bindWalkKey('Numpad3', SouthEast)
  GameInterface.bindWalkKey('Numpad2', South)
  GameInterface.bindWalkKey('Numpad1', SouthWest)
  GameInterface.bindWalkKey('Numpad4', West)
  GameInterface.bindWalkKey('Numpad7', NorthWest)

  GameInterface.bindTurnKey('Ctrl+Up', North)
  GameInterface.bindTurnKey('Ctrl+Left', West)
  GameInterface.bindTurnKey('Ctrl+Down', South)
  GameInterface.bindTurnKey('Ctrl+Right', East)
  GameInterface.bindTurnKey('Ctrl+Numpad8', North)
  GameInterface.bindTurnKey('Ctrl+Numpad4', West)
  GameInterface.bindTurnKey('Ctrl+Numpad2', South)
  GameInterface.bindTurnKey('Ctrl+Numpad6', East)

  g_keyboard.bindKeyPress('Escape', function() g_game.cancelAttackAndFollow() end, gameRootPanel)
  g_keyboard.bindKeyPress('Ctrl+=', function() gameMapPanel:zoomIn() ClientOptions.setOption('gameScreenSize', gameMapPanel:getZoom(), false) end, gameRootPanel)
  g_keyboard.bindKeyPress('Ctrl+-', function() gameMapPanel:zoomOut() ClientOptions.setOption('gameScreenSize', gameMapPanel:getZoom(), false) end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+L', function() GameInterface.tryLogout(false) end, gameRootPanel)
  -- g_keyboard.bindKeyDown('Ctrl+W', function() g_map.cleanTexts() if modules.game_textmessage then GameTextMessage.clearMessages() end end, gameRootPanel)
  g_keyboard.bindKeyDown('Ctrl+.', GameInterface.nextViewMode, gameRootPanel)

  g_keyboard.bindKeyDown('Ctrl+Shift+Q', function() ClientOptions.setOption('showTopMenu', not ClientOptions.getOption('showTopMenu')) end)
  g_keyboard.bindKeyDown('Ctrl+Shift+W', function() ClientOptions.setOption('showChat', not ClientOptions.getOption('showChat')) end)
  g_keyboard.bindKeyDown('Ctrl+Shift+A', function() ClientOptions.setOption('showLeftPanel', not ClientOptions.getOption('showLeftPanel')) end)
  g_keyboard.bindKeyDown('Ctrl+Shift+S', function() ClientOptions.setOption('showRightPanel', not ClientOptions.getOption('showRightPanel')) end)
end

function GameInterface.terminate()
  GameInterface.hide()

  hookedMenuOptions = {}
  GameInterface.stopSmartWalk()

  disconnect(bottomSplitter, {
    onDoubleClick = GameInterface.onSplitterDoubleClick,
  })

  for i = #_gamePanelsContainer, 1, -1 do
    disconnect(_gamePanelsContainer[i], {
      onFitAll = GameInterface.fitAllPanelChildren,
    })
  end

  disconnect(mouseGrabberWidget, {
    onMouseRelease = GameInterface.onMouseGrabberRelease,
  })

  disconnect(gameRootPanel, {
    onGeometryChange = GameInterface.updateStretchShrink,
    onFocusChange    = GameInterface.stopSmartWalk,
  })

  disconnect(g_game, {
    onGameStart   = GameInterface.onGameStart,
    onGameEnd     = GameInterface.onGameEnd,
    onLoginAdvice = GameInterface.onLoginAdvice
  })

  disconnect(g_app, {
    onRun  = GameInterface.load,
    onExit = GameInterface.save,
  })

  _gamePanelsContainer = {}
  _gamePanels = {}
  gamePanelsContainer = {}
  gamePanels = {}

  logoutButton:destroy()
  gameRootPanel:destroy()

  _G.GameInterface = nil
end

function GameInterface.onGameStart()
  local localPlayer = g_game.getLocalPlayer()
  g_window.setTitle(g_app.getName() .. (localPlayer and " - " .. localPlayer:getName() or ""))
  GameInterface.show()

  -- Panels width
  ClientOptions.updateOption('rightFirstPanelWidth')
  ClientOptions.updateOption('rightSecondPanelWidth')
  ClientOptions.updateOption('rightThirdPanelWidth')
  ClientOptions.updateOption('leftFirstPanelWidth')
  ClientOptions.updateOption('leftSecondPanelWidth')
  ClientOptions.updateOption('leftThirdPanelWidth')

  -- Panels stickers
  ClientOptions.updateStickers()

  g_game.enableFeature(GameForceFirstAutoWalkStep)
end

function GameInterface.onGameEnd()
  g_window.setTitle(g_app.getName())
  GameInterface.hide()
end

function GameInterface.show()
  connect(g_app, {
    onClose = GameInterface.tryExit
  })
  ClientBackground.hide()
  gameRootPanel:show()
  gameRootPanel:focus()
  gameMapPanel:followCreature(g_game.getLocalPlayer())
  GameInterface.updateViewMode()
  GameInterface.updateStretchShrink()
  logoutButton:setTooltip(tr('Logout'))
end

function GameInterface.hide()
  disconnect(g_app, {
    onClose = GameInterface.tryExit
  })
  logoutButton:setTooltip(tr('Exit'))

  if logoutWindow then
    logoutWindow:destroy()
    logoutWindow = nil
  end
  if exitWindow then
    exitWindow:destroy()
    exitWindow = nil
  end
  if countWindow then
    countWindow:destroy()
    countWindow = nil
  end
  gameRootPanel:hide()
  ClientBackground.show()
end

function GameInterface.save()
  local settings = {}
  settings.splitterMarginBottom = bottomSplitter.currentMargin
  g_settings.setNode('game_interface', settings)
end

function GameInterface.load()
  local settings = g_settings.getNode('game_interface')

  bottomSplitter.currentMargin = settings and settings.splitterMarginBottom or bottomSplitter.defaultMargin
  bottomSplitter:updateMargin()
end

function GameInterface.onLoginAdvice(message)
  displayInfoBox(tr("For Your Information"), message)
end

function GameInterface.forceExit()
  g_game.cancelLogin()
  scheduleEvent(exit, 10)
  return true
end

function GameInterface.tryExit()
  if exitWindow then
    return true
  end

  local exitFunc = function() g_game.safeLogout() GameInterface.forceExit() end
  local logoutFunc = function() g_game.safeLogout() exitWindow:destroy() exitWindow = nil end
  local cancelFunc = function() exitWindow:destroy() exitWindow = nil end

  exitWindow = displayGeneralBox(tr('Exit'), tr("If you shut down the program, your character might stay in the game.\nClick on 'Logout' to ensure that you character leaves the game properly.\nClick on 'Exit' if you want to exit the program without logging out your character."),
  { { text=tr('Force Exit'), callback=exitFunc },
    { text=tr('Logout'), callback=logoutFunc },
    { text=tr('Cancel'), callback=cancelFunc },
    anchor=AnchorHorizontalCenter }, logoutFunc, cancelFunc, 100)

  return true
end

function GameInterface.tryLogout(prompt)
  if type(prompt) ~= "boolean" then
    prompt = true
  end
  if not g_game.isOnline() then
    exit()
    return
  end

  if logoutWindow then
    return
  end

  local msg, yesCallback
  if not g_game.isConnectionOk() then
    msg = tr('Your connection is failing. If you logout now, your\ncharacter will be still online. Do you want to\nforce logout?')

    yesCallback = function()
      g_game.forceLogout()
      if logoutWindow then
        logoutWindow:destroy()
        logoutWindow=nil
        logoutButton:setOn(false)
      end
    end
  else
    msg = tr('Are you sure you want to logout?')

    yesCallback = function()
      g_game.safeLogout()
      if logoutWindow then
        logoutWindow:destroy()
        logoutWindow=nil
        logoutButton:setOn(false)
      end
    end
  end

  local noCallback = function()
    logoutWindow:destroy()
    logoutWindow=nil
    logoutButton:setOn(false)
  end

  if prompt then
    logoutWindow = displayGeneralBox(tr('Logout'), msg, {
      { text=tr('Yes'), callback=yesCallback },
      { text=tr('No'), callback=noCallback },
      anchor=AnchorHorizontalCenter}, yesCallback, noCallback)
    logoutButton:setOn(true)
  else
     yesCallback()
  end
end

function GameInterface.stopSmartWalk()
  smartWalkDirs = {}
  smartWalkDir = nil
end

function GameInterface.changeWalkDir(dir, pop)
  while table.removevalue(smartWalkDirs, dir) do end
  if pop then
    if #smartWalkDirs == 0 then
      GameInterface.stopSmartWalk()
      return
    end
  else
    table.insert(smartWalkDirs, 1, dir)
  end

  smartWalkDir = smartWalkDirs[1]
  if ClientOptions.getOption('smartWalk') and #smartWalkDirs > 1 then
    for _,d in pairs(smartWalkDirs) do
      if (smartWalkDir == North and d == West) or (smartWalkDir == West and d == North) then
        smartWalkDir = NorthWest
        break
      elseif (smartWalkDir == North and d == East) or (smartWalkDir == East and d == North) then
        smartWalkDir = NorthEast
        break
      elseif (smartWalkDir == South and d == West) or (smartWalkDir == West and d == South) then
        smartWalkDir = SouthWest
        break
      elseif (smartWalkDir == South and d == East) or (smartWalkDir == East and d == South) then
        smartWalkDir = SouthEast
        break
      end
    end
  end
end

function GameInterface.smartWalk(dir)
  if g_keyboard.getModifiers() == KeyboardNoModifier then
    local func = walkFunction
    if not func then
      local dire = smartWalkDir or dir
      if ClientOptions.getOption('smoothWalk') then
        local sensitivity = ClientOptions.getOption('walkingSensitivityScrollBar')
        g_game.smoothWalk(dire, sensitivity)
      else
        g_game.walk(dire)
      end
    end
    return true
  end
  return false
end

function GameInterface.setWalkingRepeatDelay(value)
  gameRootPanel:setAutoRepeatDelay(value)
end

function GameInterface.updateStretchShrink()
  if not ClientOptions.getOption('dontStretchShrink') or alternativeView then
    return
  end

  gameMapPanel:setVisibleDimension({ width = 15, height = 11 })

  -- Set gameMapPanel size to height = 11 * 32 + 2
  bottomSplitter:setMarginBottom(bottomSplitter:getMarginBottom() + (gameMapPanel:getHeight() - 32 * 11) - 10)
end

function GameInterface.onSplitterDoubleClick(mousePosition)
  bottomSplitter:setMarginBottom(bottomSplitter.defaultMargin)
end

local function tryChangeChild(selfHeight, childrenHeight, _childList, changeValidateCondition, changeConditionValidated, changeCondition)
  local oldChildrenHeight = childrenHeight

  local childList = {}

  for i = #_childList, 1, -1 do
    local child = _childList[i]

    local childOldHeight      = child:getHeight()
    local otherChildrenHeight = childrenHeight - childOldHeight

    if changeValidateCondition(child, childOldHeight, otherChildrenHeight) then
      childrenHeight = changeConditionValidated(child, childOldHeight, otherChildrenHeight, childList)
    end

    -- If fits enough, then resize all of childList (if not, do not resize any)
    if childrenHeight <= selfHeight then
      for _, childValue in ipairs(childList) do
        changeCondition(childValue)
      end
      return childrenHeight
    end
  end

  return oldChildrenHeight
end
local function tryResizeChildList(selfHeight, childrenHeight, _childList, noRemoveChild, resizeCondition)
  local changeValidateCondition = function(child, childOldHeight, otherChildrenHeight)
    local availableHeight = selfHeight - otherChildrenHeight -- Possible child new height
    return child:isVisible() and child:isResizeable() and child:getMinimumHeight() <= availableHeight and child:getMaximumHeight() >= availableHeight and availableHeight ~= childOldHeight and (not resizeCondition or resizeCondition(child, noRemoveChild))
  end

  local changeConditionValidated = function(child, childOldHeight, otherChildrenHeight, childList)
    local availableHeight = selfHeight - otherChildrenHeight -- Child new height
    table.insert(childList, { widget = child, height = availableHeight })
    return otherChildrenHeight + availableHeight
  end

  local changeCondition = function(childValue)
    -- addEvent(function() childValue.widget:setHeight(childValue.height) end)
    childValue.widget:setHeight(childValue.height, false, true)
  end

  return tryChangeChild(selfHeight, childrenHeight, _childList, changeValidateCondition, changeConditionValidated, changeCondition)
end
local function tryMinimizeChildList(selfHeight, childrenHeight, _childList, noRemoveChild, minimizeCondition)
  local changeValidateCondition = function(child, childOldHeight, otherChildrenHeight)
    local minimizeButton = child:getChildById('minimizeButton')
    return child:isVisible() and not minimizeButton:isOn() and (not minimizeCondition or minimizeCondition(child, noRemoveChild))
  end

  local changeConditionValidated = function(child, childOldHeight, otherChildrenHeight, childList)
    table.insert(childList, child)
    return otherChildrenHeight + child.minimizedHeight
  end

  local changeCondition = function(childValue)
    childValue:minimize(false, true)
  end

  return tryChangeChild(selfHeight, childrenHeight, _childList, changeValidateCondition, changeConditionValidated, changeCondition)
end
local function tryCloseChildList(selfHeight, childrenHeight, _childList, noRemoveChild, closeCondition)
  local changeValidateCondition = function(child, childOldHeight, otherChildrenHeight)
    return child:isVisible() and (not closeCondition or closeCondition(child, noRemoveChild))
  end

  local changeConditionValidated = function(child, childOldHeight, otherChildrenHeight, childList)
    table.insert(childList, child)
    return otherChildrenHeight
  end

  local changeCondition = function(childValue)
    childValue:close(false)
  end

  return tryChangeChild(selfHeight, childrenHeight, _childList, changeValidateCondition, changeConditionValidated, changeCondition)
end
local function isNoRemoveChild(child, noRemoveChild)
  return child == noRemoveChild
end
local function isUnsavableChildren(child, noRemoveChild)
  return child ~= noRemoveChild and not child.save
end
local function isSavableChildren(child, noRemoveChild)
  return child ~= noRemoveChild and child.save
end
-- TODO: connect to window onResize event?
function GameInterface.fitAllPanelChildren(miniWindowContainer, noRemoveChild)
  local children = miniWindowContainer:getChildren()

  local hadNoRemoveChild = noRemoveChild ~= nil

  if not noRemoveChild then
    if #children == 0 then
      return
    end

    noRemoveChild = children[#children]
  end

  local selfHeight     = miniWindowContainer:getSpaceHeight()
  local childrenHeight = miniWindowContainer:getChildrenSpaceHeight()



  -- Try to resize noRemoveChild
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryResizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isNoRemoveChild)

  -- Try to resize unsavable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryResizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isUnsavableChildren)

  -- Try to resize savable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryResizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isSavableChildren)



  -- Try move noRemoveChild (useful for savable widgets that are always loaded on same panel)
  if childrenHeight <= selfHeight then
    return
  end
  if hadNoRemoveChild then
    local nextAvailablePanel, nextAvailablePanelKey = GameInterface.getNextPanel(function(_gamePanel, k) return gamePanelsContainer[k] ~= miniWindowContainer and _gamePanel:isVisible() and gamePanelsContainer[k]:getEmptySpaceHeight() - noRemoveChild:getHeight() >= 0 end)
    if nextAvailablePanel then
      noRemoveChild:setParent(gamePanelsContainer[nextAvailablePanelKey])
      return
    end
  end



  -- Try to minimize unsavable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryMinimizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isUnsavableChildren)

  -- Try to remove unsavable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryCloseChildList(selfHeight, childrenHeight, children, noRemoveChild, isUnsavableChildren)



  -- Try to minimize savable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryMinimizeChildList(selfHeight, childrenHeight, children, noRemoveChild, isSavableChildren)

  -- Try to remove savable widgets
  if childrenHeight <= selfHeight then
    return
  end
  childrenHeight = tryCloseChildList(selfHeight, childrenHeight, children, noRemoveChild, isSavableChildren)
end

function GameInterface.setupPanels()
  local panelsPriority = ClientOptions.getOption('panelsPriority')

  -- Right
  if panelsPriority == 1 then
    -- Priority order
    gamePanels[1]          = gameRightFirstPanel
    gamePanels[2]          = gameRightSecondPanel
    gamePanels[3]          = gameRightThirdPanel
    gamePanels[4]          = gameLeftFirstPanel
    gamePanels[5]          = gameLeftSecondPanel
    gamePanels[6]          = gameLeftThirdPanel
    gamePanelsContainer[1] = gameRightFirstPanelContainer
    gamePanelsContainer[2] = gameRightSecondPanelContainer
    gamePanelsContainer[3] = gameRightThirdPanelContainer
    gamePanelsContainer[4] = gameLeftFirstPanelContainer
    gamePanelsContainer[5] = gameLeftSecondPanelContainer
    gamePanelsContainer[6] = gameLeftThirdPanelContainer

  -- Left
  elseif panelsPriority == -1 then
    -- Priority order
    gamePanels[1]          = gameLeftFirstPanel
    gamePanels[2]          = gameLeftSecondPanel
    gamePanels[3]          = gameLeftThirdPanel
    gamePanels[4]          = gameRightFirstPanel
    gamePanels[5]          = gameRightSecondPanel
    gamePanels[6]          = gameRightThirdPanel
    gamePanelsContainer[1] = gameLeftFirstPanelContainer
    gamePanelsContainer[2] = gameLeftSecondPanelContainer
    gamePanelsContainer[3] = gameLeftThirdPanelContainer
    gamePanelsContainer[4] = gameRightFirstPanelContainer
    gamePanelsContainer[5] = gameRightSecondPanelContainer
    gamePanelsContainer[6] = gameRightThirdPanelContainer

  -- None
  else
    gamePanels          = {}
    gamePanelsContainer = {}
  end
end

function GameInterface.getNextPanel(condition)
  condition = condition or function(_gamePanel, k) return _gamePanel:isVisible() end

  for gamePanelKey, gamePanel in ipairs(gamePanels) do
    if condition(gamePanel, gamePanelKey) then
      return gamePanel, gamePanelKey
    end
  end
  return nil, -1
end

function GameInterface.addToPanels(miniWindow, force)
  if #gamePanels == 0 then
    return false
  end

  -- Mini window within panel container already
  local parent = miniWindow:getParent()
  if not force and parent and parent:getClassName() == 'UIMiniWindowContainer' then
    return false
  end

  local nextAvailablePanel, nextAvailablePanelKey = GameInterface.getNextPanel(function(_gamePanel, k) return _gamePanel:isVisible() and gamePanelsContainer[k]:getEmptySpaceHeight() - miniWindow:getHeight() >= 0 end)

  -- No available panel
  if not nextAvailablePanel then
    return false
  end

  -- Attach it to available panel
  miniWindow:setParent(gamePanelsContainer[nextAvailablePanelKey])

  return true
end

function GameInterface.onContainerMiniWindowOpen(containerWindow, previousContainer)
  if not previousContainer then -- Opened in new window
    if GameInterface.addToPanels(containerWindow) then
      containerWindow:setup()
    end
  end
end

function GameInterface.toggleMiniWindow(miniWindow) -- To use on each top menu mini window
  if not miniWindow.topMenuButton then
    return
  end

  if miniWindow.topMenuButton:isOn() then
    miniWindow:close()
  else
    if not miniWindow:getSettings(true) or not miniWindow:getParent() then -- Opened for the first time or has not parent
      if not GameInterface.addToPanels(miniWindow) then
        return
      end
    end

    miniWindow:open()
  end
end

function GameInterface.setupMiniWindow(miniWindow, miniWindowButton) -- To use on each top menu mini window
  if not miniWindow or not miniWindowButton then
    return
  end

  local parent = miniWindow:getParent()
  if parent and not parent:isVisible() then
    return
  end

  -- Attach top menu button to mini window
  miniWindow.topMenuButton = miniWindowButton

  miniWindow:setup()

  if miniWindow:getSettings(true) then -- Opened once before
    if miniWindow:isVisible() then
      miniWindowButton:setOn(true)
    end
  end
end

function GameInterface.isRightPanel(panel)
  return panel.sidePanelId % 2 == 1
end

function GameInterface.isLeftPanel(panel)
  return panel.sidePanelId % 2 == 0
end

function GameInterface.isDefaultPanel(panel)
  return gamePanels[1] and panel == gamePanels[1]
end

function GameInterface.isRightPanelContainer(panelContainer)
  return isRightPanel(panelContainer:getParent())
end

function GameInterface.isLeftPanelContainer(panelContainer)
  return GameInterface.isLeftPanel(panelContainer:getParent())
end

function GameInterface.getDefaultPanel()
  return gamePanels[1]
end

function GameInterface.getDefaultPanelContainer()
  return gamePanelsContainer[1]
end

function GameInterface.setRightPanels(on)
  if on == nil then
    on = ClientOptions.getOption('showRightPanel')
  end

  gameRightFirstPanel:setVisible(on and GameInterface.isPanelEnabled(gameRightFirstPanel))
  ClientOptions.updateOption('rightFirstPanelWidth')

  gameRightSecondPanel:setVisible(on and GameInterface.isPanelEnabled(gameRightSecondPanel))
  ClientOptions.updateOption('rightSecondPanelWidth')

  gameRightThirdPanel:setVisible(on and GameInterface.isPanelEnabled(gameRightThirdPanel))
  ClientOptions.updateOption('rightThirdPanelWidth')

  rightPanelButton:setOn(on)
end

function GameInterface.setLeftPanels(on)
  if on == nil then
    on = ClientOptions.getOption('showLeftPanel')
  end

  gameLeftFirstPanel:setVisible(on and GameInterface.isPanelEnabled(gameLeftFirstPanel))
  ClientOptions.updateOption('leftFirstPanelWidth')

  gameLeftSecondPanel:setVisible(on and GameInterface.isPanelEnabled(gameLeftSecondPanel))
  ClientOptions.updateOption('leftSecondPanelWidth')

  gameLeftThirdPanel:setVisible(on and GameInterface.isPanelEnabled(gameLeftThirdPanel))
  ClientOptions.updateOption('leftThirdPanelWidth')

  leftPanelButton:setOn(on)
end

function GameInterface.movePanelMiniWindows(panelContainer)
  local children = panelContainer:getChildren()
  for _, child in ipairs(children) do
    GameInterface.addToPanels(child, true)
  end
end

function GameInterface.moveHiddenPanelMiniWindows()
  for i = 1, #gamePanelsContainer do
    if not gamePanels[i]:isVisible() then
      GameInterface.movePanelMiniWindows(gamePanelsContainer[i])
    end
  end
end

function GameInterface.isPanelEnabled(panel)
  if GameInterface.isLeftPanel(panel) then
    return panel.sidePanelId / 2 <= (ClientOptions.getOption('enabledLeftPanels') or 0)
  end
  return math.floor(panel.sidePanelId / 2) + 1 <= (ClientOptions.getOption('enabledRightPanels') or 0)
end

function GameInterface.onMouseGrabberRelease(self, mousePosition, mouseButton)
  if selectedThing == nil then
    return false
  end

  if mouseButton == MouseLeftButton then
    local clickedWidget = gameRootPanel:recursiveGetChildByPos(mousePosition, false)
    if clickedWidget then
      if selectedType == 'use' then
        GameInterface.onUseWith(clickedWidget, mousePosition)
      elseif selectedType == 'trade' then
        GameInterface.onTradeWith(clickedWidget, mousePosition)
      end
    end
  end

  selectedThing = nil
  g_mouse.popCursor('target')
  self:ungrabMouse()
  return true
end

function GameInterface.onUseWith(clickedWidget, mousePosition)
  if clickedWidget:getClassName() == 'UIGameMap' then
    local tile = clickedWidget:getTile(mousePosition)
    if tile then
      if selectedThing:isFluidContainer() or selectedThing:isMultiUse() then
        g_game.useWith(selectedThing, tile:getTopMultiUseThing())
      else
        g_game.useWith(selectedThing, tile:getTopUseThing())
      end
    end
  elseif clickedWidget:getClassName() == 'UIItem' and not clickedWidget:isVirtual() then
    g_game.useWith(selectedThing, clickedWidget:getItem())
  elseif clickedWidget:getClassName() == 'UICreatureButton' then
    local creature = clickedWidget.creature
    if creature and not creature:isPlayer() then
      -- Make possible to use with on UICreatureButton (battle window)
      g_game.useWith(selectedThing, creature)
    end
  end
end

function GameInterface.onTradeWith(clickedWidget, mousePosition)
  if clickedWidget:getClassName() == 'UIGameMap' then
    local tile = clickedWidget:getTile(mousePosition)
    if tile then
      g_game.requestTrade(selectedThing, tile:getTopCreature())
    end
  elseif clickedWidget:getClassName() == 'UICreatureButton' then
    local creature = clickedWidget.creature
    if creature then
      g_game.requestTrade(selectedThing, creature)
    end
  end
end

function GameInterface.startUseWith(thing)
  if not thing then
    return
  end

  if g_ui.isMouseGrabbed() then
    if selectedThing then
      selectedThing = thing
      selectedType = 'use'
    end
    return
  end
  selectedType = 'use'
  selectedThing = thing
  mouseGrabberWidget:grabMouse()
  g_mouse.pushCursor('target')
end

function GameInterface.startTradeWith(thing)
  if not thing then
    return
  end

  if g_ui.isMouseGrabbed() then
    if selectedThing then
      selectedThing = thing
      selectedType = 'trade'
    end
    return
  end
  selectedType = 'trade'
  selectedThing = thing
  mouseGrabberWidget:grabMouse()
  g_mouse.pushCursor('target')
end

function GameInterface.isMenuHookCategoryEmpty(category)
  if category then
    for _,opt in pairs(category) do
      if opt then
        return false
      end
    end
  end
  return true
end

function GameInterface.addMenuHook(category, name, callback, condition, shortcut)
  if not hookedMenuOptions[category] then
    hookedMenuOptions[category] = {}
  end
  hookedMenuOptions[category][name] = {
    callback = callback,
    condition = condition,
    shortcut = shortcut
  }
end

function GameInterface.removeMenuHook(category, name)
  if not name then
    hookedMenuOptions[category] = {}
  else
    hookedMenuOptions[category][name] = nil
  end
end

function GameInterface.createThingMenu(menuPosition, lookThing, useThing, creatureThing)
  if not g_game.isOnline() then
    return
  end

  local menu = g_ui.createWidget('PopupMenu')
  menu:setGameMenu(true)

  local classic = ClientOptions.getOption('classicControl')
  local shortcut = nil

  if not classic then
    shortcut = '(Shift)'
  else
    shortcut = nil
  end

  if lookThing then
    menu:addOption(tr('Look'), function() g_game.look(lookThing) end, shortcut)
  end

  if not classic then
    shortcut = '(Ctrl)'
  else
    shortcut = nil
  end

  if useThing then
    if useThing:isContainer() then
      if useThing:getParentContainer() then
        menu:addOption(tr('Open'), function() g_game.open(useThing, useThing:getParentContainer()) end, shortcut)
        menu:addOption(tr('Open in new window'), function() g_game.open(useThing) end)
      else
        menu:addOption(tr('Open'), function() g_game.open(useThing) end, shortcut)
      end
    else
      if useThing:isMultiUse() then
        menu:addOption(tr('Use with') .. ' ...', function() GameInterface.startUseWith(useThing) end, shortcut)
      else
        menu:addOption(tr('Use'), function() g_game.use(useThing) end, shortcut)
      end
    end

    if useThing:isRotateable() then
      menu:addOption(tr('Rotate'), function() g_game.rotate(useThing) end)
    end

    if g_game.getFeature(GameBrowseField) and useThing:getPosition().x ~= 0xffff then
      menu:addOption(tr('Browse field'), function() g_game.browseField(useThing:getPosition()) end)
    end
  end

  if lookThing and not lookThing:isCreature() and not lookThing:isNotMoveable() and lookThing:isPickupable() then
    menu:addSeparator()
    menu:addOption(tr('Trade with') .. ' ...', function() GameInterface.startTradeWith(lookThing) end)
  end

  if lookThing then
    local parentContainer = lookThing:getParentContainer()
    if parentContainer and parentContainer:hasParent() then
      menu:addOption(tr('Move up'), function() g_game.moveToParentContainer(lookThing, lookThing:getCount()) end)
    end
  end

  if creatureThing then
    local localPlayer = g_game.getLocalPlayer()
    local creatureName = creatureThing:getName()
    menu:addSeparator()

    if creatureThing:isLocalPlayer() then
      menu:addOption(tr('Set outfit'), function() g_game.requestOutfit() end)

      if g_game.getFeature(GamePlayerMounts) then
        if not localPlayer:isMounted() then
          menu:addOption(tr('Mount'), function() localPlayer:mount() end)
        else
          menu:addOption(tr('Dismount'), function() localPlayer:dismount() end)
        end
      end

      if creatureThing:isPartyMember() then
        if creatureThing:isPartyLeader() then
          if creatureThing:isPartySharedExperienceActive() then
            menu:addOption(tr('Disable shared XP'), function() g_game.partyShareExperience(false) end)
          else
            menu:addOption(tr('Enable shared XP'), function() g_game.partyShareExperience(true) end)
          end
        end
        menu:addOption(tr('Leave party'), function() g_game.partyLeave() end)
      end

      if g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
        menu:addSeparator()

        menu:addOption(tr('View rule violations'), function() if modules.game_ruleviolation then GameRuleViolation.showViewWindow() end end)
        menu:addOption(tr('View bugs'), function() if modules.game_bugreport then GameBugReport.showViewWindow() end end)
      end

    else
      local localPosition = localPlayer:getPosition()
      if creatureThing:getPosition().z == localPosition.z then
        if not classic then
          shortcut = '(Alt)'
        else
          shortcut = nil
        end

        if g_game.getAttackingCreature() ~= creatureThing then
          menu:addOption(tr('Attack'), function() g_game.attack(creatureThing) end, shortcut)
        else
          menu:addOption(tr('Stop attack'), function() g_game.cancelAttack() end, shortcut)
        end

        if not classic then
          shortcut = '(Ctrl+Shift)'
        else
          shortcut = nil
        end

        if g_game.getFollowingCreature() ~= creatureThing then
          menu:addOption(tr('Follow'), function() g_game.follow(creatureThing) end, shortcut)
        else
          menu:addOption(tr('Stop follow'), function() g_game.cancelFollow() end, shortcut)
        end
      end

      if creatureThing:isPlayer() then
        menu:addSeparator()

        menu:addOption(tr('Message to') .. ' ' .. creatureName, function() g_game.openPrivateChannel(creatureName) end)

        if GameConsole and GameConsole.getOwnPrivateTab() then
          menu:addOption(tr('Invite to private chat'), function() g_game.inviteToOwnChannel(creatureName) end)
          menu:addOption(tr('Exclude from private chat'), function() g_game.excludeFromOwnChannel(creatureName) end) -- [TODO] must be removed after message's popup labels been implemented
        end
        if not localPlayer:hasVip(creatureName) then
          menu:addOption(tr('Add to VIP list'), function() g_game.addVip(creatureName) end)
        end

        if GameConsole and GameConsole.isIgnored(creatureName) then
          menu:addOption(tr('Unignore') .. ' ' .. creatureName, function() if GameConsole then GameConsole.removeIgnoredPlayer(creatureName) end end)
        else
          menu:addOption(tr('Ignore') .. ' ' .. creatureName, function() if GameConsole then GameConsole.addIgnoredPlayer(creatureName) end end)
        end

        local localPlayerShield = localPlayer:getShield()
        local creatureShield = creatureThing:getShield()

        if localPlayerShield == ShieldNone or localPlayerShield == ShieldWhiteBlue then
          if creatureShield == ShieldWhiteYellow then
            menu:addOption(tr('Join %s\'s party', creatureThing:getName()), function() g_game.partyJoin(creatureThing:getId()) end)
          else
            menu:addOption(tr('Invite to party'), function() g_game.partyInvite(creatureThing:getId()) end)
          end
        elseif localPlayerShield == ShieldWhiteYellow then
          if creatureShield == ShieldWhiteBlue then
            menu:addOption(tr('Revoke %s\'s invitation', creatureThing:getName()), function() g_game.partyRevokeInvitation(creatureThing:getId()) end)
          end
        elseif localPlayerShield == ShieldYellow or localPlayerShield == ShieldYellowSharedExp or localPlayerShield == ShieldYellowNoSharedExpBlink or localPlayerShield == ShieldYellowNoSharedExp then
          if creatureShield == ShieldWhiteBlue then
            menu:addOption(tr('Revoke %s\'s invitation', creatureThing:getName()), function() g_game.partyRevokeInvitation(creatureThing:getId()) end)
          elseif creatureShield == ShieldBlue or creatureShield == ShieldBlueSharedExp or creatureShield == ShieldBlueNoSharedExpBlink or creatureShield == ShieldBlueNoSharedExp then
            menu:addOption(tr('Pass leadership to %s', creatureThing:getName()), function() g_game.partyPassLeadership(creatureThing:getId()) end)
          else
            menu:addOption(tr('Invite to party'), function() g_game.partyInvite(creatureThing:getId()) end)
          end
        end

        if localPlayer ~= creatureThing then
          menu:addSeparator()

          if g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
            menu:addOption(tr('Add rule violation'), function() if modules.game_ruleviolation then GameRuleViolation.showViewWindow(creatureName) end end)
          end

          local REPORT_TYPE_NAME      = 0
          local REPORT_TYPE_VIOLATION = 2
          menu:addOption(tr('Report name'), function() if modules.game_ruleviolation then GameRuleViolation.showRuleViolationReportWindow(REPORT_TYPE_NAME, creatureName) end end)
          menu:addOption(tr('Report violation'), function() if modules.game_ruleviolation then GameRuleViolation.showRuleViolationReportWindow(REPORT_TYPE_VIOLATION, creatureName) end end)
        end
      end
    end

    menu:addSeparator()

    menu:addOption(tr('Copy name'), function() g_window.setClipboardText(creatureName) end)
  end

  -- hooked menu options
  for _,category in pairs(hookedMenuOptions) do
    if not GameInterface.isMenuHookCategoryEmpty(category) then
      menu:addSeparator()
      for name,opt in pairs(category) do
        if opt and opt.condition(menuPosition, lookThing, useThing, creatureThing) then
          menu:addOption(name, function() opt.callback(menuPosition,
            lookThing, useThing, creatureThing) end, opt.shortcut)
        end
      end
    end
  end

  menu:display(menuPosition)
end

local function getDistanceBetween(p1, p2)
  return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

function GameInterface.processMouseAction(menuPosition, mouseButton, autoWalkPos, lookThing, useThing, creatureThing, attackCreature)
  local player = g_game.getLocalPlayer()
  local keyboardModifiers = g_keyboard.getModifiers()
  local isMouseBothPressed = g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton or g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton

  if not ClientOptions.getOption('classicControl') then
    if keyboardModifiers == KeyboardNoModifier and mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then
      GameInterface.createThingMenu(menuPosition, lookThing, useThing, creatureThing)
      return true
    elseif creatureThing and getDistanceBetween(creatureThing:getPosition(), player:getPosition()) >= 1 and (creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isCtrlPressed() and g_keyboard.isShiftPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) or not creatureThing:isMonster() and isMouseBothPressed) then
      g_game.follow(creatureThing)
      return true
    elseif attackCreature and getDistanceBetween(attackCreature:getPosition(), player:getPosition()) >= 1 and (g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) or attackCreature:isMonster() and isMouseBothPressed) then
      g_game.attack(attackCreature)
      return true
    elseif creatureThing and getDistanceBetween(creatureThing:getPosition(), player:getPosition()) >= 1 and (creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) or creatureThing:isMonster() and isMouseBothPressed) then
      g_game.attack(creatureThing)
      return true
    elseif useThing and ((keyboardModifiers == KeyboardCtrlModifier or keyboardModifiers == KeyboardAltModifier) and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) or isMouseBothPressed) then
      if keyboardModifiers == KeyboardCtrlModifier or isMouseBothPressed then
        if useThing:isContainer() then
          g_game.open(useThing, useThing:getParentContainer() and not isMouseBothPressed and useThing:getParentContainer() or nil)
          return true
        elseif useThing:isMultiUse() then
          GameInterface.startUseWith(useThing)
          return true
        end
      end
      g_game.use(useThing)
      return true
    elseif lookThing and keyboardModifiers == KeyboardShiftModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      g_game.look(lookThing)
      return true
    end

  -- Classic control
  else
    if useThing and (keyboardModifiers == KeyboardNoModifier or keyboardModifiers == KeyboardAltModifier) and mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then
      if keyboardModifiers == KeyboardNoModifier then
        if attackCreature and attackCreature ~= player then
          g_game.attack(attackCreature)
          return true
        elseif creatureThing and creatureThing ~= player and creatureThing:getPosition().z == autoWalkPos.z then
          g_game.attack(creatureThing)
          return true
        elseif useThing:isContainer() then
          g_game.open(useThing, useThing:getParentContainer() and useThing:getParentContainer() or nil)
          return true
        elseif useThing:isMultiUse() then
          GameInterface.startUseWith(useThing)
          return true
        end
      end
      g_game.use(useThing)
      return true
    elseif lookThing and keyboardModifiers == KeyboardShiftModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      g_game.look(lookThing)
      return true
    elseif lookThing and ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton) or (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
      g_game.look(lookThing)
      return true
    elseif useThing and keyboardModifiers == KeyboardCtrlModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      GameInterface.createThingMenu(menuPosition, lookThing, useThing, creatureThing)
      return true
    elseif attackCreature and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      g_game.attack(attackCreature)
      return true
    elseif creatureThing and creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
      g_game.attack(creatureThing)
      return true
    end
  end


  local player = g_game.getLocalPlayer()
  player:stopAutoWalk()

  if autoWalkPos and keyboardModifiers == KeyboardNoModifier and mouseButton == MouseLeftButton then
    player:autoWalk(autoWalkPos)
    return true
  end

  return false
end

function GameInterface.moveStackableItem(item, toPos)
  if countWindow then
    return
  end
  if g_keyboard.isCtrlPressed() then
    g_game.move(item, toPos, item:getCount())
    return
  elseif g_keyboard.isShiftPressed() then
    g_game.move(item, toPos, 1)
    return
  end
  local count = item:getCount()

  countWindow = g_ui.createWidget('CountWindow', rootWidget)
  local itembox = countWindow:getChildById('item')
  local scrollbar = countWindow:getChildById('countScrollBar')
  itembox:setItemId(item:getId())
  itembox:setItemCount(count)
  scrollbar:setMaximum(count)
  scrollbar:setMinimum(1)
  scrollbar:setValue(count)

  local spinbox = countWindow:getChildById('spinBox')
  spinbox:setMaximum(count)
  spinbox:setMinimum(0)
  spinbox:setValue(0)
  spinbox:hideButtons()
  spinbox:focus()
  spinbox.firstEdit = true

  local spinBoxValueChange = function(self, value)
    spinbox.firstEdit = false
    scrollbar:setValue(value)
  end
  spinbox.onValueChange = spinBoxValueChange

  local check = function()
    if spinbox.firstEdit then
      spinbox:setValue(spinbox:getMaximum())
      spinbox.firstEdit = false
    end
  end
  g_keyboard.bindKeyPress("Up", function() check() spinbox:up() end, spinbox)
  g_keyboard.bindKeyPress("Right", function() check() spinbox:up() end, spinbox)
  g_keyboard.bindKeyPress("Down", function() check() spinbox:down() end, spinbox)
  g_keyboard.bindKeyPress("Left", function() check() spinbox:down() end, spinbox)
  g_keyboard.bindKeyPress("PageUp", function() check() spinbox:setValue(spinbox:getValue()+10) end, spinbox)
  g_keyboard.bindKeyPress("Shift+Up", function() check() spinbox:setValue(spinbox:getValue()+10) end, spinbox)
  g_keyboard.bindKeyPress("Shift+Right", function() check() spinbox:setValue(spinbox:getValue()+10) end, spinbox)
  g_keyboard.bindKeyPress("PageDown", function() check() spinbox:setValue(spinbox:getValue()-10) end, spinbox)
  g_keyboard.bindKeyPress("Shift+Down", function() check() spinbox:setValue(spinbox:getValue()-10) end, spinbox)
  g_keyboard.bindKeyPress("Shift+Left", function() check() spinbox:setValue(spinbox:getValue()-10) end, spinbox)

  scrollbar.onValueChange = function(self, value)
    itembox:setItemCount(value)
    spinbox.onValueChange = nil
    spinbox:setValue(value)
    spinbox.onValueChange = spinBoxValueChange
  end

  scrollbar.onClick =
  function()
    local mousePos = g_window.getMousePosition()
    local slider = scrollbar:getChildById('sliderButton')
    check()
    if slider:getPosition().x > mousePos.x then
      spinbox:setValue(spinbox:getValue()-10)
    elseif slider:getPosition().x < mousePos.x then
      spinbox:setValue(spinbox:getValue()+10)
    end
  end

  local okButton = countWindow:getChildById('buttonOk')
  local moveFunc = function()
    g_game.move(item, toPos, itembox:getItemCount())
    okButton:getParent():destroy()
    countWindow = nil
  end
  local cancelButton = countWindow:getChildById('buttonCancel')
  local cancelFunc = function()
    cancelButton:getParent():destroy()
    countWindow = nil
  end

  countWindow.onEnter = moveFunc
  countWindow.onEscape = cancelFunc

  okButton.onClick = moveFunc
  cancelButton.onClick = cancelFunc
end

function GameInterface.getRootPanel()
  return gameRootPanel
end

function GameInterface.getMapPanel()
  return gameMapPanel
end

function GameInterface.getRightFirstPanel()
  return gameRightFirstPanel
end

function GameInterface.getRightSecondPanel()
  return gameRightSecondPanel
end

function GameInterface.getRightThirdPanel()
  return gameRightThirdPanel
end

function GameInterface.getLeftFirstPanel()
  return gameLeftFirstPanel
end

function GameInterface.getLeftSecondPanel()
  return gameLeftSecondPanel
end

function GameInterface.getLeftThirdPanel()
  return gameLeftThirdPanel
end

function GameInterface.getRightFirstPanelContainer()
  return gameRightFirstPanelContainer
end

function GameInterface.getRightSecondPanelContainer()
  return gameRightSecondPanelContainer
end

function GameInterface.getRightThirdPanelContainer()
  return gameRightThirdPanelContainer
end

function GameInterface.getLeftFirstPanelContainer()
  return gameLeftFirstPanelContainer
end

function GameInterface.getLeftSecondPanelContainer()
  return gameLeftSecondPanelContainer
end

function GameInterface.getLeftThirdPanelContainer()
  return gameLeftThirdPanelContainer
end

function GameInterface.getBottomPanel()
  return gameBottomPanel
end

function GameInterface.getSplitter()
  return bottomSplitter
end

function GameInterface.getGameExpBar()
  return gameExpBar
end

function GameInterface.getLeftPanelButton()
  return leftPanelButton
end

function GameInterface.getRightPanelButton()
  return rightPanelButton
end

function GameInterface.getTopMenuButton()
  return topMenuButton
end

function GameInterface.getChatButton()
  return chatButton
end

function GameInterface.getCurrentViewMode()
  return currentViewMode
end

function GameInterface.isViewModeFull()
  return ViewModes[currentViewMode].isFull
end

function GameInterface.nextViewMode()
  GameInterface.setupViewMode((currentViewMode + 1) % table.size(ViewModes))
end

function GameInterface.updateViewMode()
  local viewMode    = ViewModes[0]
  local viewModeStr = ClientOptions.getOption('viewModeComboBox')
  for k = 0, #ViewModes do
    if viewModeStr == ViewModes[k].name then
      viewMode = ViewModes[k]
      break
    end
  end
  GameInterface.setupViewMode(viewMode.id)
end

function GameInterface.setupViewMode(mode)
  if mode == currentViewMode then
    return
  end

  g_game.changeMapAwareRange(18, 14)

  local viewMode = ViewModes[mode]

  -- Anchor
  gameMapPanel:breakAnchors()
  -- Full
  if viewMode.id == 3 then
    gameMapPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    gameMapPanel:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    gameMapPanel:addAnchor(AnchorLeft, 'gameLeftThirdPanel', AnchorOutsideRight)
    gameMapPanel:addAnchor(AnchorRight, 'gameRightThirdPanel', AnchorOutsideLeft)
  -- Crop Full
  elseif viewMode.id == 2 then
    gameMapPanel:fill('parent')
  -- Crop (1) or Normal (0)
  else
    gameMapPanel:addAnchor(AnchorTop, 'parent', AnchorTop)
    gameMapPanel:addAnchor(AnchorBottom, 'gameBottomPanel', AnchorOutsideTop)
    gameMapPanel:addAnchor(AnchorLeft, 'gameLeftThirdPanel', AnchorOutsideRight)
    gameMapPanel:addAnchor(AnchorRight, 'gameRightThirdPanel', AnchorOutsideLeft)
  end

  -- Range
  gameMapPanel:setKeepAspectRatio(not viewMode.isCropped)
  gameMapPanel:setLimitVisibleRange(viewMode.isCropped)

  local panelsColor      = viewMode.id == 2 and '#ffffff66' or 'white'
  local bottomPanelColor = viewMode.isFull and '#ffffff66' or 'white'

  gameLeftFirstPanel:setImageColor(panelsColor)
  gameLeftSecondPanel:setImageColor(panelsColor)
  gameLeftThirdPanel:setImageColor(panelsColor)
  gameRightFirstPanel:setImageColor(panelsColor)
  gameRightSecondPanel:setImageColor(panelsColor)
  gameRightThirdPanel:setImageColor(panelsColor)
  gameBottomPanel:setImageColor(bottomPanelColor)

  gameBottomPanel:setOn(viewMode.isFull)

  -- Event
  gameMapPanel:changeViewMode(mode, currentViewMode)
  currentViewMode = mode

  ClientOptions.setOption('viewModeComboBox', viewMode.name, false)
end
