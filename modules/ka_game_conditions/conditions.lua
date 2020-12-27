_G.GameConditions = { }



local CONDITION_ATTR_REMAININGTIME = 1
local CONDITION_ATTR_TURNS         = 2
local CONDITION_ATTR_POWER         = 3
local CONDITION_ATTR_DESCRIPTION   = 4
local CONDITION_ATTR_ORIGINID      = 5
local CONDITION_ATTR_ORIGINNAME    = 6
local CONDITION_ATTR_ATTRIBUTE     = 7
local CONDITION_ATTR_ENDLIST       = 255

local CONDITION_ACTION_UPDATE = 1
local CONDITION_ACTION_REMOVE = 2

local CONDITION_CODE_NONAGGRESSIVE = 0
local CONDITION_CODE_AGGRESSIVE = 1

conditionList = {}



conditionTopMenuButton = nil
conditionWindow = nil
conditionHeader = nil
conditionFooter = nil
sortMenuButton = nil
arrowMenuButton = nil

filterPanel = nil
filterDefaultButton = nil
filterSelfPowersButton = nil
filterOtherPowersButton = nil
filterAggressiveButton = nil
filterNonAggressiveButton = nil

defaultConditionPanel = nil

conditionPanel = nil

CONDITION_SORT_APPEAR        = 1
CONDITION_SORT_NAME          = 2
CONDITION_SORT_PERCENTAGE    = 3
CONDITION_SORT_REMAININGTIME = 4

CONDITION_ORDER_ASCENDING    = 1
CONDITION_ORDER_DESCENDING   = 2

local conditionSortStr = {
  [CONDITION_SORT_APPEAR]        = 'Appear',
  [CONDITION_SORT_NAME]          = 'Name',
  [CONDITION_SORT_PERCENTAGE]    = 'Percentage',
  [CONDITION_SORT_REMAININGTIME] = 'Remaining Time'
}

local conditionOrderStr = {
  [CONDITION_ORDER_ASCENDING]  = 'Ascending',
  [CONDITION_ORDER_DESCENDING] = 'Descending'
}

local defaultValues = {
  filterPanel = true,
  filterDefault = true,
  filterSelfPowers = true,
  filterOtherPowers = true,
  filterAggressive = true,
  filterNonAggressive = true,
  sortType = CONDITION_SORT_APPEAR,
  sortOrder = CONDITION_ORDER_DESCENDING
}

Icons = {}
Icons[PlayerStates.Poison] = { tooltip = tr('You are poisoned'), path = '/images/game/creature/condition/default_poisoned', id = 'condition_poisoned' }
Icons[PlayerStates.Burn] = { tooltip = tr('You are burning'), path = '/images/game/creature/condition/default_burning', id = 'condition_burning' }
Icons[PlayerStates.Energy] = { tooltip = tr('You are electrified'), path = '/images/game/creature/condition/default_electrified', id = 'condition_electrified' }
Icons[PlayerStates.Drunk] = { tooltip = tr('You are drunk'), path = '/images/game/creature/condition/default_drunk', id = 'condition_drunk' }
Icons[PlayerStates.ManaShield] = { tooltip = tr('You are protected by a magic shield'), path = '/images/game/creature/condition/default_magic_shield', id = 'condition_magic_shield' }
Icons[PlayerStates.Paralyze] = { tooltip = tr('You are paralysed'), path = '/images/game/creature/condition/default_slowed', id = 'condition_slowed' }
Icons[PlayerStates.Haste] = { tooltip = tr('You are hasted'), path = '/images/game/creature/condition/default_haste', id = 'condition_haste' }
Icons[PlayerStates.Swords] = { tooltip = tr('You may not logout during a fight'), path = '/images/game/creature/condition/default_logout_block', id = 'condition_logout_block' }
Icons[PlayerStates.Drowning] = { tooltip = tr('You are drowning'), path = '/images/game/creature/condition/default_drowning', id = 'condition_drowning' }
Icons[PlayerStates.Freezing] = { tooltip = tr('You are freezing'), path = '/images/game/creature/condition/default_freezing', id = 'condition_freezing' }
Icons[PlayerStates.Dazzled] = { tooltip = tr('You are dazzled'), path = '/images/game/creature/condition/default_dazzled', id = 'condition_dazzled' }
Icons[PlayerStates.Cursed] = { tooltip = tr('You are cursed'), path = '/images/game/creature/condition/default_cursed', id = 'condition_cursed' }
Icons[PlayerStates.PartyBuff] = { tooltip = tr('You are strengthened'), path = '/images/game/creature/condition/default_strengthened', id = 'condition_strengthened' }
Icons[PlayerStates.PzBlock] = { tooltip = tr('You may not logout or enter a protection zone'), path = '/images/game/creature/condition/default_protection_zone_block', id = 'condition_protection_zone_block' }
Icons[PlayerStates.Pz] = { tooltip = tr('You are within a protection zone'), path = '/images/game/creature/condition/default_protection_zone', id = 'condition_protection_zone' }
Icons[PlayerStates.Bleeding] = { tooltip = tr('You are bleeding'), path = '/images/game/creature/condition/default_bleeding', id = 'condition_bleeding' }
Icons[PlayerStates.Hungry] = { tooltip = tr('You are hungry'), path = '/images/game/creature/condition/default_hungry', id = 'condition_hungry' }



function GameConditions.init()
  -- Alias
  GameConditions.m = modules.ka_game_conditions

  conditionList = {}

  g_ui.importStyle('conditionbutton')
  g_keyboard.bindKeyDown('Ctrl+Shift+C', GameConditions.toggle)

  conditionWindow        = g_ui.loadUI('conditions')
  conditionHeader        = conditionWindow:getChildById('miniWindowHeader')
  conditionFooter        = conditionWindow:getChildById('miniWindowFooter')
  conditionTopMenuButton = ClientTopMenu.addRightGameToggleButton('conditionTopMenuButton', tr('Conditions') .. ' (Ctrl+Shift+C)', '/images/ui/top_menu/conditions', GameConditions.toggle)

  conditionWindow.topMenuButton = conditionTopMenuButton

  for k,v in pairs(Icons) do
    g_textures.preload(v.path)
  end

  -- This disables scrollbar auto hiding
  local scrollbar = conditionWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = {} })

  sortMenuButton = conditionWindow:getChildById('sortMenuButton')
  GameConditions.setSortType(GameConditions.getSortType())
  GameConditions.setSortOrder(GameConditions.getSortOrder())

  arrowMenuButton = conditionWindow:getChildById('arrowMenuButton')
  arrowMenuButton:setOn(not g_settings.getValue('Conditions', 'filterPanel', defaultValues.filterPanel))
  GameConditions.onClickArrowMenuButton(arrowMenuButton)

  filterPanel           = conditionHeader:getChildById('filterPanel')
  defaultConditionPanel = conditionFooter:getChildById('defaultConditionPanel')

  filterDefaultButton       = filterPanel:getChildById('filterDefault')
  filterSelfPowersButton    = filterPanel:getChildById('filterSelfPowers')
  filterOtherPowersButton   = filterPanel:getChildById('filterOtherPowers')
  filterAggressiveButton    = filterPanel:getChildById('filterAggressive')
  filterNonAggressiveButton = filterPanel:getChildById('filterNonAggressive')
  filterDefaultButton:setOn(not g_settings.getValue('Conditions', 'filterDefault', defaultValues.filterDefault))
  filterSelfPowersButton:setOn(not g_settings.getValue('Conditions', 'filterSelfPowers', defaultValues.filterSelfPowers))
  filterOtherPowersButton:setOn(not g_settings.getValue('Conditions', 'filterOtherPowers', defaultValues.filterOtherPowers))
  filterAggressiveButton:setOn(not g_settings.getValue('Conditions', 'filterAggressive', defaultValues.filterAggressive))
  filterNonAggressiveButton:setOn(not g_settings.getValue('Conditions', 'filterNonAggressive', defaultValues.filterNonAggressive))
  GameConditions.onClickFilterDefault(filterDefaultButton)
  GameConditions.onClickFilterSelfPowers(filterSelfPowersButton)
  GameConditions.onClickFilterOtherPowers(filterOtherPowersButton)
  GameConditions.onClickFilterAggressive(filterAggressiveButton)
  GameConditions.onClickFilterNonAggressive(filterNonAggressiveButton)

  conditionPanel = conditionWindow:getChildById('contentsPanel'):getChildById('conditionPanel')

  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodeConditionsList, GameConditions.parseConditions)
  connect(g_game, {
    onGameStart = GameConditions.online,
    onGameEnd   = GameConditions.offline
  })
  connect(LocalPlayer, {
    onStatesChange = GameConditions.onStatesChange
  })

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    GameConditions.onStatesChange(localPlayer, localPlayer:getStates(), 0)
  end

  GameInterface.setupMiniWindow(conditionWindow, conditionTopMenuButton)
end

function GameConditions.terminate()
  conditionList = {}

  disconnect(LocalPlayer, {
    onStatesChange = GameConditions.onStatesChange
  })
  disconnect(g_game, {
    onGameStart = GameConditions.online,
    onGameEnd   = GameConditions.offline
  })

  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodeConditionsList)

  conditionTopMenuButton:destroy()
  conditionWindow:destroy()

  g_keyboard.unbindKeyDown('Ctrl+Shift+C')

  _G.GameConditions = nil
end



function GameConditions.getConditionIndex(id, subId)
  for i, condition in pairs(conditionList) do
    if condition.id == id and condition.subId == subId then
      return i
    end
  end
  return nil
end

function GameConditions.addCondition(condition)
  condition.startTime = os.time()
  condition.button = g_ui.createWidget('ConditionButton')
  condition.button:setup(condition)
  table.insert(conditionList, condition)
  conditionPanel:addChild(condition.button)
  GameConditions.updateConditionList()
end

function GameConditions.removeCondition(condition)
  local index = GameConditions.getConditionIndex(condition.id, condition.subId)
  if index then
    if conditionList[index] then
      conditionList[index].button:destroy()
    end
    table.remove(conditionList, index)
    GameConditions.updateConditionList()
  -- else
  --   print("Trying to remove invalid condition")
  end
end

--[[
  Condition Object:
  - (number)  id
  - (number)  subId
  - (string)  name
  - (boolean) isAgressive

  - (number)  remainingTime (optional)
  - (number)  turns (optional)
  - (number)  powerId (optional)
  - (number)  boost (optional)
]]
function GameConditions.parseConditions(protocol, msg)
  local action = msg:getU8()

  local condition = {}
  condition.id    = msg:getU8()
  condition.subId = msg:getU8()

  -- Insert / Update
  if action == CONDITION_ACTION_UPDATE then
    condition.name       = msg:getString()
    condition.aggressive = msg:getU8() == CONDITION_CODE_AGGRESSIVE

    local nextByte = msg:getU8()
    while nextByte ~= CONDITION_ATTR_ENDLIST do
      if nextByte == CONDITION_ATTR_REMAININGTIME then
        condition.remainingTime = msg:getU32()
      elseif nextByte == CONDITION_ATTR_TURNS then
        condition.turns = msg:getU32()
      elseif nextByte == CONDITION_ATTR_POWER then
        condition.powerId = msg:getU8()
        condition.powerName = msg:getString()
        condition.boost = msg:getU8()
      elseif nextByte == CONDITION_ATTR_DESCRIPTION then
        condition.description = msg:getString()
      elseif nextByte == CONDITION_ATTR_ORIGINID then
        condition.originId = msg:getU32()
      elseif nextByte == CONDITION_ATTR_ORIGINNAME then
        condition.originName = msg:getString()
      elseif nextByte == CONDITION_ATTR_ATTRIBUTE then
        condition.attribute = msg:getU8()
        condition.offset = msg:getString()
        condition.factor = msg:getString()
      else
        print("Unknown byte: " .. nextByte)
      end
      nextByte = msg:getU8()
    end
    GameConditions.addCondition(condition)

  -- Remove
  elseif action == CONDITION_ACTION_REMOVE then
    GameConditions.removeCondition(condition)
  end
end



function GameConditions.online()
  GameInterface.setupMiniWindow(conditionWindow, conditionTopMenuButton)
end

function GameConditions.offline()
  GameConditions.clearList()
end

function GameConditions.toggle()
  GameInterface.toggleMiniWindow(conditionWindow)
end

-- Filtering
function GameConditions.onClickArrowMenuButton(self)
  local newState = not self:isOn()
  arrowMenuButton:setOn(newState)
  conditionHeader:setOn(not newState)
  g_settings.setValue('Conditions', 'filterPanel', newState)
end

function GameConditions.conditionButtonFilter(condition)
  local filterDefault       = not filterDefaultButton:isOn()
  local filterSelfPowers    = not filterSelfPowersButton:isOn()
  local filterOtherPowers   = not filterOtherPowersButton:isOn()
  local filterAggressive    = not filterAggressiveButton:isOn()
  local filterNonAggressive = not filterNonAggressiveButton:isOn()

  local isAggressive = condition.aggressive
  local isPower      = condition.power and condition.power > 0
  local isOwn        = condition.originId and g_game.getLocalPlayer():getId() == condition.originId
  return filterSelfPowers and isPower and isOwn or filterOtherPowers and isPower and not isOwn or filterAggressive and isAggressive or filterNonAggressive and not isAggressive or false
end

function GameConditions.filterConditionButtons()
  for i, condition in pairs(conditionList) do
    condition.button:setOn(not GameConditions.conditionButtonFilter(condition))
  end
end

function GameConditions.onClickFilterDefault(self)
  local newState = not self:isOn()
  filterDefaultButton:setOn(newState)
  conditionFooter:setOn(not newState)
  g_settings.setValue('Conditions', 'filterDefault', newState)
end

function GameConditions.onClickFilterSelfPowers(self)
  local newState = not self:isOn()
  filterSelfPowersButton:setOn(newState)
  g_settings.setValue('Conditions', 'filterSelfPowers', newState)
  GameConditions.filterConditionButtons()
end

function GameConditions.onClickFilterOtherPowers(self)
  local newState = not self:isOn()
  filterOtherPowersButton:setOn(newState)
  g_settings.setValue('Conditions', 'filterOtherPowers', newState)
  GameConditions.filterConditionButtons()
end

function GameConditions.onClickFilterAggressive(self)
  local newState = not self:isOn()
  filterAggressiveButton:setOn(newState)
  g_settings.setValue('Conditions', 'filterAggressive', newState)
  GameConditions.filterConditionButtons()
end

function GameConditions.onClickFilterNonAggressive(self)
  local newState = not self:isOn()
  filterNonAggressiveButton:setOn(newState)
  g_settings.setValue('Conditions', 'filterNonAggressive', newState)
  GameConditions.filterConditionButtons()
end

-- Sorting
function GameConditions.getSortType()
  return g_settings.getValue('Conditions', 'sortType', defaultValues.sortType)
end

function GameConditions.setSortType(state)
  g_settings.setValue('Conditions', 'sortType', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', conditionSortStr[state] or '', conditionOrderStr[GameConditions.getSortOrder()] or ''))
  GameConditions.updateConditionList()
end

function GameConditions.getSortOrder()
  return g_settings.getValue('Conditions', 'sortOrder', defaultValues.sortOrder)
end

function GameConditions.setSortOrder(state)
  g_settings.setValue('Conditions', 'sortOrder', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', conditionSortStr[GameConditions.getSortType()] or '', conditionOrderStr[state] or ''))
  GameConditions.updateConditionList()
end

function GameConditions.createSortMenu()
  local menu = g_ui.createWidget('PopupMenu')

  local sortOrder = GameConditions.getSortOrder()
  if sortOrder == CONDITION_ORDER_ASCENDING then
    menu:addOption(tr('%s Order', conditionOrderStr[CONDITION_ORDER_DESCENDING]), function() GameConditions.setSortOrder(CONDITION_ORDER_DESCENDING) end)
  elseif sortOrder == CONDITION_ORDER_DESCENDING then
    menu:addOption(tr('%s Order', conditionOrderStr[CONDITION_ORDER_ASCENDING]), function() GameConditions.setSortOrder(CONDITION_ORDER_ASCENDING) end)
  end

  menu:addSeparator()

  local sortType = GameConditions.getSortType()
  if sortType ~= CONDITION_SORT_APPEAR then
    menu:addOption(tr('Sort by %s', conditionSortStr[CONDITION_SORT_APPEAR]), function() GameConditions.setSortType(CONDITION_SORT_APPEAR) end)
  end
  if sortType ~= CONDITION_SORT_NAME then
    menu:addOption(tr('Sort by %s', conditionSortStr[CONDITION_SORT_NAME]), function() GameConditions.setSortType(CONDITION_SORT_NAME) end)
  end
  if sortType ~= CONDITION_SORT_PERCENTAGE then
    menu:addOption(tr('Sort by %s', conditionSortStr[CONDITION_SORT_PERCENTAGE]), function() GameConditions.setSortType(CONDITION_SORT_PERCENTAGE) end)
  end
  if sortType ~= CONDITION_SORT_REMAININGTIME then
    menu:addOption(tr('Sort by %s', conditionSortStr[CONDITION_SORT_REMAININGTIME]), function() GameConditions.setSortType(CONDITION_SORT_REMAININGTIME) end)
  end

  menu:display()
end

function GameConditions.sortConditions()
  local sortFunction
  local sortOrder = GameConditions.getSortOrder()
  local sortType  = GameConditions.getSortType()

  if sortOrder == CONDITION_ORDER_ASCENDING then
    if sortType == CONDITION_SORT_APPEAR then
      sortFunction = function(a,b)
        return a.startTime < b.startTime
      end

    elseif sortType == CONDITION_SORT_NAME then
      sortFunction = function(a,b)
        return a.name < b.name
      end

    elseif sortType == CONDITION_SORT_PERCENTAGE then
      sortFunction = function(a,b)
        return a.button.clock:getPercent() < b.button.clock:getPercent()
      end

    elseif sortType == CONDITION_SORT_REMAININGTIME then
      sortFunction = function(a,b)
        return a.button.clock:getRemainingTime() < b.button.clock:getRemainingTime()
      end
    end

  elseif sortOrder == CONDITION_ORDER_DESCENDING then
    if sortType == CONDITION_SORT_APPEAR then
      sortFunction = function(a,b)
        return a.startTime > b.startTime
      end

    elseif sortType == CONDITION_SORT_NAME then
      sortFunction = function(a,b)
        return a.name > b.name
      end

    elseif sortType == CONDITION_SORT_PERCENTAGE then
      sortFunction = function(a,b)
        return a.button.clock:getPercent() > b.button.clock:getPercent()
      end

    elseif sortType == CONDITION_SORT_REMAININGTIME then
      sortFunction = function(a,b)
        return a.button.clock:getRemainingTime() > b.button.clock:getRemainingTime()
      end
    end
  end

  if sortFunction then
    table.sort(conditionList, sortFunction)
  end
end

function GameConditions.updateConditionList()
  GameConditions.sortConditions()
  for i = 1, #conditionList do
    conditionPanel:moveChildToIndex(conditionList[i].button, i)
  end
  GameConditions.filterConditionButtons()
end

function GameConditions.clearListConditionPanel()
  conditionList = {}
  conditionPanel:destroyChildren()
end

function GameConditions.clearListDefaultConditionPanel()
  defaultConditionPanel:destroyChildren()
end

function GameConditions.clearList()
  GameConditions.clearListConditionPanel()
  GameConditions.clearListDefaultConditionPanel()
end

-- Default conditions

function GameConditions.loadIcon(bitChanged)
  local icon = g_ui.createWidget('ConditionWidget', content)
  icon:setId(Icons[bitChanged].id)
  icon:setImageSource(Icons[bitChanged].path)
  icon:setTooltip(Icons[bitChanged].tooltip)
  return icon
end

function GameConditions.toggleIcon(bitChanged)
  local content = conditionFooter:getChildById('defaultConditionPanel')

  if Icons[bitChanged] then
    local icon = content:getChildById(Icons[bitChanged].id)
    if icon then
      icon:destroy()
    else
      icon = GameConditions.loadIcon(bitChanged)
      icon:setParent(content)
    end
  end
end

function GameConditions.onStatesChange(localPlayer, now, old)
  if now == old then
    return
  end

  local bitsChanged = bit32.bxor(now, old)
  for i = 1, 32 do
    local pow = math.pow(2, i-1)
    if pow > bitsChanged then
      break
    end

    local bitChanged = bit32.band(bitsChanged, pow)
    if bitChanged ~= 0 then
      GameConditions.toggleIcon(bitChanged)
    end
  end
end
