_G.GameBattleList = { }



battleTopMenuButton = nil
battleWindow = nil
battleHeader = nil
sortMenuButton = nil
arrowMenuButton = nil

filterPlayersButton = nil
filterNPCsButton = nil
filterMonstersButton = nil
filterSkullsButton = nil
filterPartyButton = nil

battlePanel = nil

mouseWidget = nil
lastButtonSwitched = nil



-- Sorting

BATTLE_SORT_APPEAR   = 1
BATTLE_SORT_DISTANCE = 2
BATTLE_SORT_HEALTH   = 3
BATTLE_SORT_NAME     = 4

BATTLE_ORDER_ASCENDING  = 1
BATTLE_ORDER_DESCENDING = 2

BATTLE_SORT_STR =
{
  [BATTLE_SORT_APPEAR]   = 'Display Time',
  [BATTLE_SORT_DISTANCE] = 'Distance',
  [BATTLE_SORT_HEALTH]   = 'Hitpoints',
  [BATTLE_SORT_NAME]     = 'Name',
}

BATTLE_ORDER_STR =
{
  [BATTLE_ORDER_ASCENDING]  = 'Ascending',
  [BATTLE_ORDER_DESCENDING] = 'Descending'
}

local defaultValues =
{
  filterPanel = true,

  filterPlayers  = true,
  filterNPCs     = true,
  filterMonsters = true,
  filterSkulls   = true,
  filterParty    = true,

  sortType  = BATTLE_SORT_DISTANCE,
  sortOrder = BATTLE_ORDER_ASCENDING
}

-- Position checking
local lastPosCheck = g_clock.millis()
BATTLELIST_POS_UPDATE_DELAY = 1000



function GameBattleList.init()
  -- Alias
  GameBattleList.m = modules.game_battlelist

  battleList        = {}
  battleListByIndex = {}

  g_ui.importStyle('battlelistbutton')
  g_keyboard.bindKeyDown('Ctrl+B', GameBattleList.toggle)

  battleWindow = g_ui.loadUI('battlelist')
  battleTopMenuButton = ClientTopMenu.addRightGameToggleButton('battleTopMenuButton', tr('Battle List') .. ' (Ctrl+B)', '/images/ui/top_menu/battle_list', GameBattleList.toggle)

  battleWindow.topMenuButton = battleTopMenuButton

  battleHeader = battleWindow:getChildById('miniWindowHeader')

  -- This disables scrollbar auto hiding
  local scrollbar = battleWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = {} })

  sortMenuButton = battleWindow:getChildById('sortMenuButton')
  GameBattleList.setSortType(GameBattleList.getSortType())
  GameBattleList.setSortOrder(GameBattleList.getSortOrder())

  arrowMenuButton = battleWindow:getChildById('arrowMenuButton')
  arrowMenuButton:setOn(not g_settings.getValue('BattleList', 'filterPanel', defaultValues.filterPanel))
  GameBattleList.onClickArrowMenuButton(arrowMenuButton)

  local _filterPanel   = battleHeader:getChildById('filterPanel')
  filterPlayersButton  = _filterPanel:getChildById('filterPlayers')
  filterNPCsButton     = _filterPanel:getChildById('filterNPCs')
  filterMonstersButton = _filterPanel:getChildById('filterMonsters')
  filterSkullsButton   = _filterPanel:getChildById('filterSkulls')
  filterPartyButton    = _filterPanel:getChildById('filterParty')
  filterPlayersButton:setOn(not g_settings.getValue('BattleList', 'filterPlayers', defaultValues.filterPlayers))
  filterNPCsButton:setOn(not g_settings.getValue('BattleList', 'filterNPCs', defaultValues.filterNPCs))
  filterMonstersButton:setOn(not g_settings.getValue('BattleList', 'filterMonsters', defaultValues.filterMonsters))
  filterSkullsButton:setOn(not g_settings.getValue('BattleList', 'filterSkulls', defaultValues.filterSkulls))
  filterPartyButton:setOn(not g_settings.getValue('BattleList', 'filterParty', defaultValues.filterParty))
  GameBattleList.onClickFilterPlayers(filterPlayersButton)
  GameBattleList.onClickFilterNPCs(filterNPCsButton)
  GameBattleList.onClickFilterMonsters(filterMonstersButton)
  GameBattleList.onClickFilterSkulls(filterSkullsButton)
  GameBattleList.onClickFilterParty(filterPartyButton)

  battlePanel = battleWindow:getChildById('contentsPanel'):getChildById('battlePanel')

  mouseWidget = g_ui.createWidget('UIButton')
  mouseWidget:setVisible(false)
  mouseWidget:setFocusable(false)
  mouseWidget.cancelNextRelease = false

  connect(Creature, {
    onAppear              = GameBattleList.onAppear,
    onDisappear           = GameBattleList.onDisappear,
    onPositionChange      = GameBattleList.onPositionChange,
    onTypeChange          = GameBattleList.onTypeChange,
    onShieldChange        = GameBattleList.onShieldChange,
    onSkullChange         = GameBattleList.onSkullChange,
    onEmblemChange        = GameBattleList.onEmblemChange,
    onSpecialIconChange   = GameBattleList.onSpecialIconChange,
    onHealthPercentChange = GameBattleList.onHealthPercentChange,
    onNicknameChange      = GameBattleList.onNicknameChange
  })

  connect(LocalPlayer, {
    onPositionChange = GameBattleList.onPositionChange
  })

  connect(g_game, {
    onAttackingCreatureChange = GameBattleList.onAttackingCreatureChange,
    onFollowingCreatureChange = GameBattleList.onFollowingCreatureChange,
    onGameStart               = GameBattleList.online,
    onGameEnd                 = GameBattleList.offline
  })

  GameBattleList.refreshList()

  GameInterface.setupMiniWindow(battleWindow, battleTopMenuButton)
end

function GameBattleList.terminate()
  battleList        = {}
  battleListByIndex = {}

  disconnect(g_game, {
    onAttackingCreatureChange = GameBattleList.onAttackingCreatureChange,
    onFollowingCreatureChange = GameBattleList.onFollowingCreatureChange,
    onGameStart               = GameBattleList.online,
    onGameEnd                 = GameBattleList.offline
  })

  disconnect(LocalPlayer, {
    onPositionChange = GameBattleList.onPositionChange
  })

  disconnect(Creature, {
    onAppear              = GameBattleList.onAppear,
    onDisappear           = GameBattleList.onDisappear,
    onPositionChange      = GameBattleList.onPositionChange,
    onTypeChange          = GameBattleList.onTypeChange,
    onShieldChange        = GameBattleList.onShieldChange,
    onSkullChange         = GameBattleList.onSkullChange,
    onEmblemChange        = GameBattleList.onEmblemChange,
    onSpecialIconChange   = GameBattleList.onSpecialIconChange,
    onHealthPercentChange = GameBattleList.onHealthPercentChange,
    onNicknameChange      = GameBattleList.onNicknameChange
  })

  mouseWidget:destroy()

  battleTopMenuButton:destroy()
  battleWindow:destroy()

  g_keyboard.unbindKeyDown('Ctrl+B')

  _G.GameBattleList = nil
end

function GameBattleList.online()
  GameInterface.setupMiniWindow(battleWindow, battleTopMenuButton)
end

function GameBattleList.offline()
  GameBattleList.clearList()
end

function GameBattleList.toggle()
  GameInterface.toggleMiniWindow(battleWindow)
end



-- Button

function GameBattleList.getButtonIndex(cid)
  for k, button in pairs(battleListByIndex) do
    if cid == button.creature:getId() then
      return k
    end
  end
  return nil
end

function GameBattleList.add(creature)
  local localPlayer = g_game.getLocalPlayer()
  if creature == localPlayer then
    return
  end

  local cid = creature:getId()
  local button = battleList[cid]

  -- Register first time creature adding
  if not button then
    button = g_ui.createWidget('BattleButton')
    button:setup(creature)

    button.onHoverChange  = GameBattleList.onBattleButtonHoverChange
    button.onMouseRelease = GameBattleList.onBattleButtonMouseRelease

    battleList[cid] = button
    table.insert(battleListByIndex, battleList[cid])

    if creature == g_game.getAttackingCreature() then
      GameBattleList.onAttackingCreatureChange(creature)
    end
    if creature == g_game.getFollowingCreature() then
      GameBattleList.onFollowingCreatureChange(creature)
    end

    battlePanel:addChild(button)
    GameBattleList.updateList()
  end
end

function GameBattleList.remove(creature)
  local cid   = creature:getId()
  local index = GameBattleList.getButtonIndex(cid)
  if index then
    if battleList[cid] then
      if battleList[cid] == lastButtonSwitched then
        lastButtonSwitched = nil
      end
      battleList[cid]:destroy()
      battleList[cid] = nil
    end
    table.remove(battleListByIndex, index)
  -- else
  --   print("Trying to remove invalid battleButton")
  end
end

function GameBattleList.updateBattleButton(self)
  self:update()
  if self.isTarget or self.isFollowed then
    if lastButtonSwitched and lastButtonSwitched ~= self then
      lastButtonSwitched.isTarget = false
      lastButtonSwitched.isFollowed = false
      GameBattleList.updateBattleButton(lastButtonSwitched)
    end
    lastButtonSwitched = self
  end
end

function GameBattleList.updateBattleButtons()
  for _, button in ipairs(battleListByIndex) do
    GameBattleList.updateBattleButton(button)
  end
end

function GameBattleList.onBattleButtonHoverChange(self, hovered)
  if self.isBattleButton then
    self.isHovered = hovered
    GameBattleList.updateBattleButton(self)
  end
end

function GameBattleList.onBattleButtonMouseRelease(self, mousePosition, mouseButton)
  if mouseWidget.cancelNextRelease then
    mouseWidget.cancelNextRelease = false
    return false
  end
  if mouseButton == MouseLeftButton and g_keyboard.isCtrlPressed() and g_keyboard.isShiftPressed() then
    g_game.follow(self.creature)
  elseif g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton or g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton then
    mouseWidget.cancelNextRelease = true
    g_game.look(self.creature, true)
    return true
  elseif mouseButton == MouseLeftButton and g_keyboard.isShiftPressed() then
    g_game.look(self.creature, true)
    return true
  elseif mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then
    GameInterface.createThingMenu(mousePosition, nil, nil, self.creature)
    return true
  elseif mouseButton == MouseLeftButton and not g_mouse.isPressed(MouseRightButton) then
    if self.isTarget then
      g_game.cancelAttack()
    else
      g_game.attack(self.creature)
    end
    return true
  end
  return false
end

function GameBattleList.updateStaticSquare()
  for _, button in pairs(battleList) do
    if button.isTarget then
      button:update()
    end
  end
end



-- Filtering

function GameBattleList.onClickArrowMenuButton(self)
  local newState = not self:isOn()
  arrowMenuButton:setOn(newState)
  battleHeader:setOn(not newState)
  g_settings.setValue('BattleList', 'filterPanel', newState)
end

function GameBattleList.buttonFilter(button)
  local filterPlayers  = not filterPlayersButton:isOn()
  local filterNPCs     = not filterNPCsButton:isOn()
  local filterMonsters = not filterMonstersButton:isOn()
  local filterSkulls   = not filterSkullsButton:isOn()
  local filterParty    = not filterPartyButton:isOn()

  local creature = button.creature
  return filterPlayers and creature:isPlayer() or filterNPCs and creature:isNpc() or filterMonsters and creature:isMonster() or filterSkulls and (creature:getSkull() == SkullNone or creature:getSkull() == SkullProtected) or filterParty and creature:getShield() > ShieldWhiteBlue or false
end

function GameBattleList.filterButtons()
  for _, _button in pairs(battleList) do
    local on = not GameBattleList.buttonFilter(_button)
    local localPlayer = g_game.getLocalPlayer()
    if localPlayer and localPlayer:getPosition().z ~= _button.creature:getPosition().z then
      on = false
    end
    _button:setOn(on)
  end
end

function GameBattleList.onClickFilterPlayers(self)
  local newState = not self:isOn()
  filterPlayersButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterPlayers', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterNPCs(self)
  local newState = not self:isOn()
  filterNPCsButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterNPCs', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterMonsters(self)
  local newState = not self:isOn()
  filterMonstersButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterMonsters', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterSkulls(self)
  local newState = not self:isOn()
  filterSkullsButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterSkulls', newState)
  GameBattleList.filterButtons()
end

function GameBattleList.onClickFilterParty(self)
  local newState = not self:isOn()
  filterPartyButton:setOn(newState)
  g_settings.setValue('BattleList', 'filterParty', newState)
  GameBattleList.filterButtons()
end



-- Sorting

function GameBattleList.getSortType()
  return g_settings.getValue('BattleList', 'sortType', defaultValues.sortType)
end

function GameBattleList.setSortType(state)
  g_settings.setValue('BattleList', 'sortType', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', BATTLE_SORT_STR[state] or '', BATTLE_ORDER_STR[GameBattleList.getSortOrder()] or ''))
  GameBattleList.updateList()
end

function GameBattleList.getSortOrder()
  return g_settings.getValue('BattleList', 'sortOrder', defaultValues.sortOrder)
end

function GameBattleList.setSortOrder(state)
  g_settings.setValue('BattleList', 'sortOrder', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', BATTLE_SORT_STR[GameBattleList.getSortType()] or '', BATTLE_ORDER_STR[state] or ''))
  GameBattleList.updateList()
end

function GameBattleList.createSortMenu()
  local menu = g_ui.createWidget('PopupMenu')

  local sortOrder = GameBattleList.getSortOrder()
  local sortType  = GameBattleList.getSortType()

  if sortOrder == BATTLE_ORDER_ASCENDING then
    menu:addOption(tr('%s Order', BATTLE_ORDER_STR[BATTLE_ORDER_DESCENDING]), function() GameBattleList.setSortOrder(BATTLE_ORDER_DESCENDING) end)
  elseif sortOrder == BATTLE_ORDER_DESCENDING then
    menu:addOption(tr('%s Order', BATTLE_ORDER_STR[BATTLE_ORDER_ASCENDING]), function() GameBattleList.setSortOrder(BATTLE_ORDER_ASCENDING) end)
  end

  menu:addSeparator()

  if sortType ~= BATTLE_SORT_APPEAR then
    menu:addOption(tr('Sort by %s', BATTLE_SORT_STR[BATTLE_SORT_APPEAR]), function() GameBattleList.setSortType(BATTLE_SORT_APPEAR) end)
  end
  if sortType ~= BATTLE_SORT_DISTANCE then
    menu:addOption(tr('Sort by %s', BATTLE_SORT_STR[BATTLE_SORT_DISTANCE]), function() GameBattleList.setSortType(BATTLE_SORT_DISTANCE) end)
  end
  if sortType ~= BATTLE_SORT_HEALTH then
    menu:addOption(tr('Sort by %s', BATTLE_SORT_STR[BATTLE_SORT_HEALTH]), function() GameBattleList.setSortType(BATTLE_SORT_HEALTH) end)
  end
  if sortType ~= BATTLE_SORT_NAME then
    menu:addOption(tr('Sort by %s', BATTLE_SORT_STR[BATTLE_SORT_NAME]), function() GameBattleList.setSortType(BATTLE_SORT_NAME) end)
  end

  menu:display()
end

function GameBattleList.sortList()
  local sortFunction

  local sortOrder = GameBattleList.getSortOrder()
  local sortType  = GameBattleList.getSortType()

  if sortOrder == BATTLE_ORDER_ASCENDING then
    -- Ascending - Appear
    if sortType == BATTLE_SORT_APPEAR then
      sortFunction = function(a,b) return a.lastAppear < b.lastAppear end

    -- Ascending - Distance
    elseif sortType == BATTLE_SORT_DISTANCE then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()

        sortFunction = function(a,b) return getDistanceTo(localPlayerPos, a.creature:getPosition()) < getDistanceTo(localPlayerPos, b.creature:getPosition()) end
      end

    -- Ascending - Health
    elseif sortType == BATTLE_SORT_HEALTH then
      sortFunction = function(a,b) return a.creature:getHealthPercent() < b.creature:getHealthPercent() end

    -- Ascending - Name
    elseif sortType == BATTLE_SORT_NAME then
      sortFunction = function(a,b) return a.creature:getName() < b.creature:getName() end
    end

  elseif sortOrder == BATTLE_ORDER_DESCENDING then
    -- Descending - Appear
    if sortType == BATTLE_SORT_APPEAR then
      sortFunction = function(a,b) return a.lastAppear > b.lastAppear end

    -- Descending - Distance
    elseif sortType == BATTLE_SORT_DISTANCE then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()

        sortFunction = function(a,b) return getDistanceTo(localPlayerPos, a.creature:getPosition()) > getDistanceTo(localPlayerPos, b.creature:getPosition()) end
      end

    -- Descending - Health
    elseif sortType == BATTLE_SORT_HEALTH then
      sortFunction = function(a,b) return a.creature:getHealthPercent() > b.creature:getHealthPercent() end

    -- Descending - Name
    elseif sortType == BATTLE_SORT_NAME then
      sortFunction = function(a,b) return a.creature:getName() > b.creature:getName() end
    end
  end

  if sortFunction then
    table.sort(battleListByIndex, sortFunction)
  end
end

function GameBattleList.updateList()
  GameBattleList.sortList()
  for i = 1, #battleListByIndex do
    battlePanel:moveChildToIndex(battleListByIndex[i], i)
  end
  GameBattleList.filterButtons()
end

function GameBattleList.clearList()
  lastButtonSwitched = nil
  battleList         = { }
  battleListByIndex  = { }
  battlePanel:destroyChildren()
end

function GameBattleList.refreshList()
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  GameBattleList.clearList()

  for _, creature in pairs(g_map.getSpectators(localPlayer:getPosition(), true)) do
    GameBattleList.add(creature)
  end
end



-- Events

function GameBattleList.onAttackingCreatureChange(creature)
  local button = creature and battleList[creature:getId()] or lastButtonSwitched
  if button then
    button.isTarget = creature and true or false
    GameBattleList.updateBattleButton(button)
  end
end

function GameBattleList.onFollowingCreatureChange(creature)
  local button = creature and battleList[creature:getId()] or lastButtonSwitched
  if button then
    button.isFollowed = creature and true or false
    GameBattleList.updateBattleButton(button)
  end
end

function GameBattleList.onAppear(creature)
  if creature:isLocalPlayer() then
    addEvent(function()
      GameBattleList.updateStaticSquare()
    end)
  end

  GameBattleList.add(creature)
end

function GameBattleList.onDisappear(creature)
  GameBattleList.remove(creature)
end

function GameBattleList.onPositionChange(creature, pos, oldPos)
  local posCheck = g_clock.millis()
  local diffTime = posCheck - lastPosCheck

  if  creature == g_game.getLocalPlayer() and pos and oldPos and pos.z ~= oldPos.z or
      GameBattleList.getSortType() == BATTLE_SORT_DISTANCE and diffTime > BATTLELIST_POS_UPDATE_DELAY
  then
    GameBattleList.updateList()

    lastPosCheck = posCheck
  end
end

function GameBattleList.onTypeChange(creature, typeId, oldTypeId)
  local button = battleList[creature:getId()]
  if button then
    button:updateCreatureType(typeId)
  end
end

function GameBattleList.onShieldChange(creature, shieldId)
  local button = battleList[creature:getId()]
  if button then
    button:updateShield(shieldId)
  end
end

function GameBattleList.onSkullChange(creature, skullId, oldSkullId)
  local button = battleList[creature:getId()]
  if button then
    button:updateSkull(skullId)
  end
end

function GameBattleList.onEmblemChange(creature, emblemId)
  local button = battleList[creature:getId()]
  if button then
    button:updateEmblem(emblemId)
  end
end

function GameBattleList.onSpecialIconChange(creature, specialIconId)
  local button = battleList[creature:getId()]
  if button then
    button:updateSpecialIcon(specialIconId)
  end
end

function GameBattleList.onHealthPercentChange(creature, healthPercent)
  local button = battleList[creature:getId()]
  if button then
    button:updateHealthPercent(healthPercent)

    if GameBattleList.getSortType() == BATTLE_SORT_HEALTH then
      GameBattleList.updateList()
    end
  end
end

function GameBattleList.onNicknameChange(creature, nickname)
  local button = battleList[creature:getId()]
  if button then
    button:updateLabelText(nickname)

    if GameBattleList.getSortType() == BATTLE_SORT_NAME then
      GameBattleList.updateList()
    end
  end
end
