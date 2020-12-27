_G.GameTextMessage = { }



DefaultFont = 'verdana-11px-rounded'

MessageSettings =
{
  none            = {},
  consoleRed      = { color = TextColors.red,       consoleTab='Default' },
  consoleOrange   = { color = TextColors.orange,    consoleTab='Default' },
  consoleBlue     = { color = TextColors.blue,      consoleTab='Default' },
  centerRed       = { color = TextColors.red,       consoleTab='Server', screenTarget='lowCenterLabel' },
  centerGreen     = { color = TextColors.green,     consoleTab='Server', screenTarget='highCenterLabel',   consoleOption='showInfoMessagesInConsole' },
  centerWhite     = { color = TextColors.white,     consoleTab='Server', screenTarget='middleCenterLabel', consoleOption='showEventMessagesInConsole' },
  bottomWhite     = { color = TextColors.white,     consoleTab='Server', screenTarget='statusLabel',       consoleOption='showEventMessagesInConsole' },
  status          = { color = TextColors.white,     consoleTab='Server', screenTarget='statusLabel',       consoleOption='showStatusMessagesInConsole' },
  statusSmall     = { color = TextColors.white,                          screenTarget='statusLabel' },
  loot            = { color = TextColors.green,     consoleTab='Server' },
  private         = { color = TextColors.lightblue,                      screenTarget='privateLabel' },
  statusBigTop    = { color = '#e1e1e1',            consoleTab='Server', screenTarget='privateLabel',      consoleOption='showStatusMessagesInConsole', font='sans-bold-borded-16px' },
  statusBigCenter = { color = '#e1e1e1',            consoleTab='Server', screenTarget='middleCenterLabel', consoleOption='showStatusMessagesInConsole', font='sans-bold-borded-16px' },
  statusBigBottom = { color = '#e1e1e1',            consoleTab='Server', screenTarget='statusLabel',       consoleOption='showStatusMessagesInConsole', font='sans-bold-borded-16px' },
}

MessageTypes =
{
  [MessageModes.MonsterSay] = MessageSettings.consoleOrange,
  [MessageModes.MonsterYell] = MessageSettings.consoleOrange,
  [MessageModes.BarkLow] = MessageSettings.consoleOrange,
  [MessageModes.BarkLoud] = MessageSettings.consoleOrange,
  [MessageModes.Failure] = MessageSettings.statusSmall,
  [MessageModes.Login] = MessageSettings.bottomWhite,
  [MessageModes.Game] = MessageSettings.centerWhite,
  [MessageModes.Status] = MessageSettings.status,
  [MessageModes.Warning] = MessageSettings.centerRed,
  [MessageModes.Look] = MessageSettings.centerGreen,
  [MessageModes.Loot] = MessageSettings.loot,
  [MessageModes.Red] = MessageSettings.consoleRed,
  [MessageModes.Blue] = MessageSettings.consoleBlue,
  [MessageModes.PrivateFrom] = MessageSettings.consoleBlue,

  [MessageModes.GamemasterBroadcast] = MessageSettings.consoleRed,

  [MessageModes.DamageDealed] = MessageSettings.status,
  [MessageModes.DamageReceived] = MessageSettings.status,
  [MessageModes.Heal] = MessageSettings.status,
  [MessageModes.Exp] = MessageSettings.status,

  [MessageModes.DamageOthers] = MessageSettings.none,
  [MessageModes.HealOthers] = MessageSettings.none,
  [MessageModes.ExpOthers] = MessageSettings.none,

  [MessageModes.TradeNpc] = MessageSettings.centerWhite,
  [MessageModes.Guild] = MessageSettings.centerWhite,
  [MessageModes.Party] = MessageSettings.centerGreen,
  [MessageModes.PartyManagement] = MessageSettings.centerWhite,
  [MessageModes.TutorialHint] = MessageSettings.centerWhite,
  [MessageModes.BeyondLast] = MessageSettings.centerWhite,
  [MessageModes.Report] = MessageSettings.consoleRed,
  [MessageModes.HotkeyUse] = MessageSettings.centerGreen,

  [MessageModes.MessageGameBigTop] = MessageSettings.statusBigTop,
  [MessageModes.MessageGameBigCenter] = MessageSettings.statusBigCenter,
  [MessageModes.MessageGameBigBottom] = MessageSettings.statusBigBottom,

  [254] = MessageSettings.private
}

messagesPanel = nil
statusLabel = nil



function GameTextMessage.init()
  -- Alias
  GameTextMessage.m = modules.game_textmessage

  for messageMode, _ in pairs(MessageTypes) do
    registerMessageMode(messageMode, GameTextMessage.displayMessage)
  end

  connect(g_game, {
    onClientOptionChanged = GameTextMessage.onClientOptionChanged,
    onGameEnd             = GameTextMessage.clearMessages,
  })
  connect(GameInterface.getMapPanel(), {
    onGeometryChange = GameTextMessage.onGeometryChange,
    onViewModeChange = GameTextMessage.onViewModeChange,
    onZoomChange     = GameTextMessage.onZoomChange,
  })

  messagesPanel = g_ui.loadUI('textmessage', GameInterface.getRootPanel())
  statusLabel = messagesPanel:getChildById('statusLabel')
end

function GameTextMessage.terminate()
  for messageMode, _ in pairs(MessageTypes) do
    unregisterMessageMode(messageMode, GameTextMessage.displayMessage)
  end

  disconnect(GameInterface.getMapPanel(), {
    onGeometryChange = GameTextMessage.onGeometryChange,
    onViewModeChange = GameTextMessage.onViewModeChange,
    onZoomChange     = GameTextMessage.onZoomChange,
  })
  disconnect(g_game, {
    onClientOptionChanged = GameTextMessage.onClientOptionChanged,
    onGameEnd             = GameTextMessage.clearMessages,
  })

  GameTextMessage.clearMessages()
  messagesPanel:destroy()

  _G.GameTextMessage = nil
end

local function updateStatusLabelPosition(label)
  local margin = GameInterface.m.chatButton:getHeight() + 4

  -- Hotkey bar
  local firstHotkeybar = modules.ka_game_hotkeybars and GameHotkeybars.getHotkeyBars()[1] or nil
  if firstHotkeybar and firstHotkeybar:isVisible() then
    margin = margin + firstHotkeybar.height + firstHotkeybar.mapMargin
  end

  -- Experience bar
  if GameInterface.m.gameExpBar:isOn() then
    margin = margin + GameInterface.m.gameExpBar:getHeight()
  end

  label:setMarginBottom(margin)
end

function GameTextMessage.onGeometryChange(mapPanel)
  updateStatusLabelPosition(statusLabel)
end

function GameTextMessage.onViewModeChange(mapWidget, viewMode, oldViewMode)
  updateStatusLabelPosition(statusLabel)
end

function GameTextMessage.onClientOptionChanged(key, value, force, wasClientSettingUp)
  updateStatusLabelPosition(statusLabel)
end

function GameTextMessage.onZoomChange(self, oldZoom, newZoom)
  if oldZoom == newZoom then
    return
  end

  addEvent(function() updateStatusLabelPosition(statusLabel) end)
end

function GameTextMessage.calculateVisibleTime(text)
  return math.max(#text * 100, 4000)
end

function GameTextMessage.displayMessage(mode, text)
  if not g_game.isOnline() then
    return
  end

  local msgtype = MessageTypes[mode]
  if not msgtype then
    return
  end

  if msgtype == MessageSettings.none then
    return
  end

  if msgtype.consoleTab ~= nil and (msgtype.consoleOption == nil or ClientOptions.getOption(msgtype.consoleOption)) then
    GameConsole.addText(text, msgtype, tr(msgtype.consoleTab))
    --TODO move to game_console
  end

  if msgtype.screenTarget then
    local label = messagesPanel:recursiveGetChildById(msgtype.screenTarget)
    label:setText(text)
    label:setColor(msgtype.color)
    label:setFont(msgtype.font or DefaultFont)
    label:setVisible(true)
    if msgtype.screenTarget == 'statusLabel' then
      updateStatusLabelPosition(label)
    end
    removeEvent(label.hideEvent)
    label.hideEvent = scheduleEvent(function() label:setVisible(false) end, GameTextMessage.calculateVisibleTime(text))
  end
end

function GameTextMessage.displayPrivateMessage(text)
  GameTextMessage.displayMessage(254, text)
end

function GameTextMessage.displayStatusMessage(text)
  GameTextMessage.displayMessage(MessageModes.Status, text)
end

function GameTextMessage.displayFailureMessage(text)
  GameTextMessage.displayMessage(MessageModes.Failure, text)
end

function GameTextMessage.displayGameMessage(text)
  GameTextMessage.displayMessage(MessageModes.Game, text)
end

function GameTextMessage.displayBroadcastMessage(text)
  GameTextMessage.displayMessage(MessageModes.Warning, text)
end

function GameTextMessage.clearMessages()
  for _i,child in pairs(messagesPanel:recursiveGetChildren()) do
    if child:getId():match('Label') then
      child:hide()
      removeEvent(child.hideEvent)
    end
  end
end



function LocalPlayer:onAutoWalkFail(player)
  if modules.game_textmessage then
    GameTextMessage.displayFailureMessage(tr('There is no way.'))
  end
end
