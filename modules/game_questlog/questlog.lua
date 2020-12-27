_G.GameQuestLog = { }



questLogButton = nil
questLineWindow = nil

local questLogTeleportLock = false

function GameQuestLog.init()
  -- Alias
  GameQuestLog.m = modules.game_questlog

  g_ui.importStyle('questlogwindow')
  g_ui.importStyle('questlinewindow')

  questLogButton = ClientTopMenu.addLeftGameButton('questLogButton', tr('Quest Log') .. ' (Ctrl+Q)', '/images/ui/top_menu/questlog', GameQuestLog.toggle)

  connect(g_game, {
    onGameEnd = GameQuestLog.destroyWindows
  })
  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeQuestLog, GameQuestLog.parseQuestLog)
  g_keyboard.bindKeyDown('Ctrl+Q', GameQuestLog.toggle)
end

function GameQuestLog.terminate()
  g_keyboard.unbindKeyDown('Ctrl+Q')
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeQuestLog)
  disconnect(g_game, {
    onGameEnd = GameQuestLog.destroyWindows
  })

  GameQuestLog.destroyWindows()
  questLogButton:destroy()

  _G.GameQuestLog = nil
end

-- For avoid multiple teleport confirm windows
function GameQuestLog.getTeleportLock()
  return questLogTeleportLock
end
function GameQuestLog.setTeleportLock(lock)
  questLogTeleportLock = lock
end

function GameQuestLog.destroyWindows()
  if questLogWindow then
    questLogWindow:destroy()
  end

  if questLineWindow then
    questLineWindow:destroy()
  end
end

function GameQuestLog.show()
  if not g_game.canPerformGameAction() then
    return
  end

  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeQuestLog)
  msg:addString('')
  protocolGame:send(msg)

  questLogButton:setOn(true)
end

function GameQuestLog.hide()
  GameQuestLog.destroyWindows()
  questLogButton:setOn(false)
end

function GameQuestLog.toggle()
  if not questLogWindow or not questLogWindow:isVisible() then
    GameQuestLog.show()
  else
    GameQuestLog.hide()
  end
end

function GameQuestLog.sendTeleportRequest(questId, missionId)
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    return false
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeAction)
  msg:addString(string.format('%i:%i:%i', ClientActions.QuestTeleports, questId, missionId))
  protocolGame:send(msg)

  return true
end

function GameQuestLog.sendShowItemsRequest(questId, missionId)
  local protocolGame = g_game.getProtocolGame()
  if protocolGame then
    return false
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeAction)
  msg:addString(string.format('%i:%i:%i', ClientActions.QuestItems, questId, missionId))
  protocolGame:send(msg)

  return true
end

function GameQuestLog.onRowUpdate(child)
  if child then
    if not child.isComplete and not child.canDo then
      child:setBackgroundColor('#ff000020')
    end
    child.mainDataLabel:setColor(child:isFocused() and '#ffffff' or '#333b43')
  end
end

function GameQuestLog.updateLayout(window, questId, missionId, row)
  if not window then
    return
  end
  local teleportButton             = window:getChildById('teleportButton')
  local rewardsLabel               = window:getChildById('rewardsLabel')
  local rewardExperienceLabel      = window:getChildById('rewardExperienceLabel')
  local rewardExperienceValueLabel = window:getChildById('rewardExperienceValueLabel')
  local rewardMoneyLabel           = window:getChildById('rewardMoneyLabel')
  local rewardMoneyValueLabel      = window:getChildById('rewardMoneyValueLabel')
  local itemsButton                = window:getChildById('itemsButton')
  local otherRewards               = window:getChildById('otherRewards')
  local otherRewardsScrollBar      = window:getChildById('otherRewardsScrollBar')
  local rowsList                   = row.parent

  if row.hasTeleport then
    teleportButton:setVisible(true)

    teleportButton.onClick = function()
      if not GameQuestLog.getTeleportLock() then
        local buttonCallback = function()
          GameQuestLog.sendTeleportRequest(questId, missionId)
          if modules.game_questlog then
            GameQuestLog.setTeleportLock(false)
          end
        end

        local onCancelCallback = function()
          if modules.game_questlog then
            GameQuestLog.setTeleportLock(false)
          end
        end

        displayCustomBox('Quest Teleport', 'Are you sure that you want to teleport?', {{ text = 'Yes', buttonCallback = buttonCallback }}, 1, 'No', onCancelCallback, nil)
        GameQuestLog.setTeleportLock(true)
      end
    end
  else
    teleportButton:setVisible(false)
  end

  if row.experience >= 1 then
    rewardExperienceLabel:setVisible(true)
    rewardExperienceValueLabel:setVisible(true)
    rewardExperienceValueLabel:setText(tr('%d XP', row.experience))
  else
    rewardExperienceLabel:setVisible(false)
    rewardExperienceValueLabel:setVisible(false)
  end

  if row.money >= 1 then
    rewardMoneyLabel:setVisible(true)
    rewardMoneyValueLabel:setVisible(true)
    rewardMoneyValueLabel:setText(tr('%d GPs', row.money))
  else
    rewardMoneyLabel:setVisible(false)
    rewardMoneyValueLabel:setVisible(false)
  end

  if row.showItems then
    itemsButton:setVisible(true)
    itemsButton.onClick = function()
      GameQuestLog.sendShowItemsRequest(questId, missionId)
    end
  else
    itemsButton:setVisible(false)
  end

  if row.otherRewards and row.otherRewards ~= "" then
    otherRewards:setVisible(true)
    otherRewards:setText(row.otherRewards)
    otherRewardsScrollBar:setVisible(true)
  else
    otherRewards:setVisible(false)
    otherRewardsScrollBar:setVisible(false)
  end

  rewardsLabel:setVisible(rewardExperienceValueLabel:isVisible() or rewardMoneyValueLabel:isVisible() or itemsButton:isVisible() or otherRewards:isVisible())

  if rowsList and rowsList:hasChildren() then
    local children = rowsList:getChildren()
    if #children >= 1 then
      for i = 1, #children do
        GameQuestLog.onRowUpdate(children[i])
      end
    end
  end
end

function GameQuestLog.parseQuestLog(protocolGame, opcode, msg)
  local buffer = msg:getString()
  local params = buffer:split(':::')

  local mode = tonumber(params[1])
  if not mode then
    return
  end

  if mode == 1 then -- Quest Log
    local quests = {}

    for _, _quest in ipairs(params[2] and params[2]:split(';;') or {}) do
      local quest = {}
      local data = _quest:split("::")
      quest.id = tonumber(data[1])
      if not quest.id then
        return
      end

      quest.isComplete   = tonumber(data[2]) == 1 and true or false
      quest.canDo        = tonumber(data[3]) == 1 and true or false
      quest.logName      = data[4]
      quest.categoryName = data[5]
      quest.minLevel     = tonumber(data[6]) or 1
      quest.hasTeleport  = tonumber(data[7]) == 1 and true or false
      quest.experience   = tonumber(data[8]) or 0
      quest.money        = tonumber(data[9]) or 0
      quest.showItems    = tonumber(data[10]) == 1 and true or false
      quest.otherRewards = data[11]
      quest.otherRewards = quest.otherRewards ~= '-' and quest.otherRewards or ''
      table.insert(quests, quest)
    end
    GameQuestLog.onGameQuestLog(quests)

  elseif mode == 2 then -- Quest Line
    local missions = {}
    local questId = tonumber(params[2])
    if not questId then
      return
    end

    for _, _mission in ipairs(params[3] and params[3]:split(';;') or {}) do
      local mission = {}
      local data = _mission:split('::')
      mission.id = tonumber(data[1])
      if mission.id then
        mission.isComplete   = tonumber(data[2]) == 1 and true or false
        mission.canDo        = tonumber(data[3]) == 1 and true or false
        mission.logName      = data[4]
        mission.minLevel     = tonumber(data[5]) or 1
        mission.description  = data[6]
        mission.hasTeleport  = tonumber(data[7]) == 1 and true or false
        mission.experience   = tonumber(data[8]) or 0
        mission.money        = tonumber(data[9]) or 0
        mission.showItems    = tonumber(data[10]) == 1 and true or false
        mission.otherRewards = data[11]
        mission.otherRewards = mission.otherRewards ~= '-' and mission.otherRewards or ''
        table.insert(missions, mission)
      end
    end
    GameQuestLog.onGameQuestLine(questId, missions)
  end
end

function GameQuestLog.onGameQuestLog(quests)
  GameQuestLog.destroyWindows()

  questLogWindow = g_ui.createWidget('QuestLogWindow', rootWidget)
  local questList = questLogWindow:getChildById('questList')

  connect(questList, {
    onChildFocusChange = function(self, focusedChild)
      if focusedChild == nil then
        return
      end

      GameQuestLog.updateLayout(questLogWindow, focusedChild.questId, 0, focusedChild)
    end
  })

  for _, quest in ipairs(quests) do
    local questLabel = g_ui.createWidget('QuestLabel', questList)
    questLabel.parent = questList
    questLabel.questId = quest.id
    questLabel.isComplete = quest.isComplete
    questLabel:setOn(quest.isComplete)
    questLabel.canDo = quest.canDo
    questLabel.logName = quest.logName
    questLabel.categoryName = quest.categoryName
    questLabel.minLevel = quest.minLevel
    questLabel:setText(quest.logName)
    questLabel.hasTeleport = quest.hasTeleport
    questLabel.experience = quest.experience
    questLabel.money = quest.money
    questLabel.showItems = quest.showItems
    questLabel.otherRewards = quest.otherRewards

    local questMainDataLabel = g_ui.createWidget('QuestDataLabel', questLabel)
    questMainDataLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
    questMainDataLabel:setText('[' .. quest.categoryName .. ']'  .. (quest.minLevel > 1 and ' [Lv ' .. quest.minLevel .. ']' or ''))
    questLabel.mainDataLabel = questMainDataLabel

    GameQuestLog.onRowUpdate(questLabel)
    questLabel.onDoubleClick =
    function()
      if not g_game.canPerformGameAction() then
        return
      end

      local protocolGame = g_game.getProtocolGame()
      if not protocolGame then
        return
      end

      questLogWindow:hide()

      local msg = OutputMessage.create()
      msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
      msg:addU16(ClientExtOpcodes.ClientExtOpcodeQuestLog)
      msg:addString(tostring(quest.id))
      protocolGame:send(msg)
    end

  end

  questLogWindow.onDestroy = function()
    questLogWindow = nil
  end

  --questList:focusChild(questList:getFirstChild())
end

function GameQuestLog.onGameQuestLine(questId, missions)
  if questLogWindow then
    questLogWindow:hide()
  end

  if questLineWindow then
    questLineWindow:destroy()
  end

  questLineWindow = g_ui.createWidget('QuestLineWindow', rootWidget)
  local missionList = questLineWindow:getChildById('missionList')
  local missionDescription = questLineWindow:getChildById('missionDescription')

  connect(missionList, {
    onChildFocusChange = function(self, focusedChild)
      if focusedChild == nil then
        return
      end

      missionDescription:setText(focusedChild.description)
      GameQuestLog.updateLayout(questLineWindow, questId, focusedChild.missionId, focusedChild)
    end
  })

  for _, mission in pairs(missions) do
    local missionLabel = g_ui.createWidget('MissionLabel')
    missionLabel.parent = missionList
    missionLabel.missionId = mission.id
    missionLabel.isComplete = mission.isComplete
    missionLabel:setOn(mission.isComplete)
    missionLabel.canDo = mission.canDo
    missionLabel.logName = mission.logName
    missionLabel.minLevel = mission.minLevel
    missionLabel:setText(mission.logName)
    missionLabel.description = mission.description
    missionLabel.hasTeleport = mission.hasTeleport
    missionLabel.experience = mission.experience
    missionLabel.money = mission.money
    missionLabel.showItems = mission.showItems
    missionLabel.otherRewards = mission.otherRewards

    local missionMainDataLabel = g_ui.createWidget('MissionDataLabel', missionLabel)
    missionMainDataLabel:addAnchor(AnchorRight, 'parent', AnchorRight)
    missionMainDataLabel:setText((mission.minLevel > 1 and '[Lv ' .. mission.minLevel .. ']' or ''))
    missionLabel.mainDataLabel = missionMainDataLabel

    GameQuestLog.onRowUpdate(missionLabel)
    missionList:addChild(missionLabel)
  end

  questLineWindow.onDestroy = function()
    if questLogWindow then
      questLogWindow:show()
    end

    questLineWindow = nil
  end

  --missionList:focusChild(missionList:getFirstChild())
end

function GameQuestLog.questLogWindowFocus()
  if questLogWindow then
    questLogWindow:focus()
  end
end
