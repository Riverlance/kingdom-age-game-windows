_G.GamePartyList = { }



partyTopMenuButton = nil
partyWindow = nil
partyHeader = nil
contentsPanel = nil
arrowMenuButton = nil
sortMenuButton = nil
emptyMenuButton = nil

partyLevelCalculatorWindow = nil
levelTextEdit = nil
levelLabel = nil

partyPanel = nil
inviteePanel = nil

inviteeLabel = nil
partyLabel = nil
separator = nil

mouseWidget = nil
lastButtonSwitched = nil



partyList          = { }
partyListByIndex   = { }
inviteeList        = { }
inviteeListByIndex = { }



-- Filtering

filterPlayersButton = nil
filterSummonsButton = nil
filterKnightPlayersButton = nil
filterPaladinPlayersButton = nil
filterArcherPlayersButton = nil
filterAssassinPlayersButton = nil
filterWizardPlayersButton = nil
filterBardPlayersButton = nil

-- Sorting

SortTypeHierarchy = 1
SortTypeAppear    = 2
SortTypeDistance  = 3
SortTypeHealth    = 4
SortTypeMana      = 5
SortTypeName      = 6
SortTypePing      = 7

SortOrderAscending  = 1
SortOrderDescending = 2

SortTypeStr =
{
  [SortTypeHierarchy] = 'Hierarchy',
  [SortTypeAppear]    = 'Display Time',
  [SortTypeDistance]  = 'Distance',
  [SortTypeHealth]    = 'Hitpoints',
  [SortTypeMana]      = 'Manapoints',
  [SortTypeName]      = 'Name',
  [SortTypePing]      = 'Ping',
}

SortOrderStr =
{
  [SortOrderAscending]  = 'Ascending',
  [SortOrderDescending] = 'Descending',
}

local defaultValues =
{
  filterPanel = true,

  filterPlayers         = true,
  filterSummons         = true,
  filterKnightPlayers   = true,
  filterPaladinPlayers  = true,
  filterArcherPlayers   = true,
  filterAssassinPlayers = true,
  filterWizardPlayers   = true,
  filterBardPlayers     = true,

  sortType  = SortTypeHierarchy,
  sortOrder = SortOrderAscending,
}

-- Timed update checking
local lastUpdateCheck = g_clock.millis()
TimedUpdateDelay      = 1000



PARTYLIST_SERVERSIGNAL_CREATE                     = 1
PARTYLIST_SERVERSIGNAL_JOIN                       = 2
PARTYLIST_SERVERSIGNAL_LEAVE                      = 3
PARTYLIST_SERVERSIGNAL_DISBAND                    = 4
PARTYLIST_SERVERSIGNAL_ADDINVITE                  = 5
PARTYLIST_SERVERSIGNAL_REMOVEINVITE               = 6
PARTYLIST_SERVERSIGNAL_SENDCREATUREOUTFIT         = 7
PARTYLIST_SERVERSIGNAL_SENDCREATURENICKNAME       = 8
PARTYLIST_SERVERSIGNAL_SENDCREATURESHIELD         = 9
PARTYLIST_SERVERSIGNAL_SENDCREATURESKULL          = 10
PARTYLIST_SERVERSIGNAL_SENDCREATURESPECIALICON    = 11
PARTYLIST_SERVERSIGNAL_SENDCREATURESPOSITION      = 12
PARTYLIST_SERVERSIGNAL_SENDCREATUREHEALTHPERCENT  = 13
PARTYLIST_SERVERSIGNAL_SENDCREATUREMANAPERCENT    = 14
PARTYLIST_SERVERSIGNAL_SENDPLAYERSPING            = 15
PARTYLIST_SERVERSIGNAL_SENDVOCATIONID             = 16
PARTYLIST_SERVERSIGNAL_SENDEXTRAEXPERIENCETOOLTIP = 17

-- PARTYLIST_CLIENTSIGNAL_REQUESTPOSITIONS = 1 -- Example



local function getCid(data)
  return type(data) == 'userdata' and not isWidget(data) and data:getId() or type(data) == 'table' and data.cid or type(data) == 'number' and data or nil
end



function GamePartyList.init()
  -- Alias
  GamePartyList.m = modules.ka_game_partylist

  -- Data

  partyList          = { }
  partyListByIndex   = { }
  inviteeList        = { }
  inviteeListByIndex = { }

  -- Window

  g_ui.importStyle('partylistbutton')
  g_ui.importStyle('partylevelcalculatorwindow')

  partyWindow = g_ui.loadUI('partylist')
  partyTopMenuButton = ClientTopMenu.addRightGameToggleButton('partyTopMenuButton', tr('Party List') .. ' (Ctrl+P)', '/images/ui/top_menu/party_list', GamePartyList.toggle)

  partyWindow.topMenuButton = partyTopMenuButton

  partyHeader = partyWindow:getChildById('miniWindowHeader')

  g_keyboard.bindKeyDown('Ctrl+P', GamePartyList.toggle)

  -- This disables scrollbar auto hiding
  local scrollbar = partyWindow:getChildById('miniwindowScrollBar')
  scrollbar:mergeStyle({ ['$!on'] = { } })

  contentsPanel = partyWindow:getChildById('contentsPanel')

  partyPanel   = contentsPanel:getChildById('partyPanel')
  inviteePanel = contentsPanel:getChildById('inviteePanel')

  inviteeLabel = contentsPanel:getChildById('inviteeLabel')
  partyLabel   = contentsPanel:getChildById('separator')
  separator    = contentsPanel:getChildById('partyLabel')

  mouseWidget = g_ui.createWidget('UIButton')
  mouseWidget:setVisible(false)
  mouseWidget:setFocusable(false)
  mouseWidget.cancelNextRelease = false

  arrowMenuButton = partyWindow:getChildById('arrowMenuButton')
  arrowMenuButton:setOn(not g_settings.getValue('PartyList', 'filterPanel', defaultValues.filterPanel))
  GamePartyList.onClickArrowMenuButton(arrowMenuButton)

  sortMenuButton = partyWindow:getChildById('sortMenuButton')
  GamePartyList.setSortType(GamePartyList.getSortType())
  GamePartyList.setSortOrder(GamePartyList.getSortOrder())

  emptyMenuButton = partyWindow:getChildById('emptyMenuButton')

  partyLevelCalculatorWindow = g_ui.createWidget('PartyLevelCalculatorWindow', rootWidget)
  levelTextEdit              = partyLevelCalculatorWindow:getChildById('levelTextEdit')
  levelLabel                 = partyLevelCalculatorWindow:getChildById('levelLabel')
  GamePartyList.partyLevelCalculatorWindowHide()

  local _filterPanel          = partyHeader:getChildById('filterPanel')
  filterPlayersButton         = _filterPanel:getChildById('filterPlayers')
  filterSummonsButton         = _filterPanel:getChildById('filterSummons')
  filterKnightPlayersButton   = _filterPanel:getChildById('filterKnightPlayers')
  filterPaladinPlayersButton  = _filterPanel:getChildById('filterPaladinPlayers')
  filterArcherPlayersButton   = _filterPanel:getChildById('filterArcherPlayers')
  filterAssassinPlayersButton = _filterPanel:getChildById('filterAssassinPlayers')
  filterWizardPlayersButton   = _filterPanel:getChildById('filterWizardPlayers')
  filterBardPlayersButton     = _filterPanel:getChildById('filterBardPlayers')
  filterPlayersButton:setOn(not g_settings.getValue('PartyList', 'filterPlayers', defaultValues.filterPlayers))
  filterSummonsButton:setOn(not g_settings.getValue('PartyList', 'filterSummons', defaultValues.filterSummons))
  filterKnightPlayersButton:setOn(not g_settings.getValue('PartyList', 'filterKnightPlayers', defaultValues.filterKnightPlayers))
  filterPaladinPlayersButton:setOn(not g_settings.getValue('PartyList', 'filterPaladinPlayers', defaultValues.filterPaladinPlayers))
  filterArcherPlayersButton:setOn(not g_settings.getValue('PartyList', 'filterArcherPlayers', defaultValues.filterArcherPlayers))
  filterAssassinPlayersButton:setOn(not g_settings.getValue('PartyList', 'filterAssassinPlayers', defaultValues.filterAssassinPlayers))
  filterWizardPlayersButton:setOn(not g_settings.getValue('PartyList', 'filterWizardPlayers', defaultValues.filterWizardPlayers))
  filterBardPlayersButton:setOn(not g_settings.getValue('PartyList', 'filterBardPlayers', defaultValues.filterBardPlayers))
  GamePartyList.onClickFilterPlayers(filterPlayersButton)
  GamePartyList.onClickFilterSummons(filterSummonsButton)
  GamePartyList.onClickFilterKnightPlayers(filterKnightPlayersButton)
  GamePartyList.onClickFilterPaladinPlayers(filterPaladinPlayersButton)
  GamePartyList.onClickFilterArcherPlayers(filterArcherPlayersButton)
  GamePartyList.onClickFilterAssassinPlayers(filterAssassinPlayersButton)
  GamePartyList.onClickFilterWizardPlayers(filterWizardPlayersButton)
  GamePartyList.onClickFilterBardPlayers(filterBardPlayersButton)

  ProtocolGame.registerOpcode(ServerOpcodes.ServerOpcodePartyList, GamePartyList.parsePartyList)

  connect(Creature, {
    -- onShieldChange = GamePartyList.onShieldChange,
    -- onSkullChange  = GamePartyList.onSkullChange,
    onWalk         = GamePartyList.onWalk,
  })

  connect(g_game, {
    onGameStart = GamePartyList.online,
    onGameEnd   = GamePartyList.offline,
    onPingBack  = GamePartyList.updateLocalPlayerPing,
    -- onFollowingCreatureChange = GamePartyList.onFollowingCreatureChange,
  })

  GamePartyList.refreshList()

  GameInterface.setupMiniWindow(partyWindow, partyTopMenuButton)
end

function GamePartyList.terminate()
  GamePartyList.offline()

  disconnect(g_game, {
    onGameStart = GamePartyList.online,
    onGameEnd   = GamePartyList.offline,
    onPingBack  = GamePartyList.updateLocalPlayerPing,
    -- onFollowingCreatureChange = GamePartyList.onFollowingCreatureChange,
  })

  disconnect(Creature, {
    -- onShieldChange = GamePartyList.onShieldChange,
    -- onSkullChange  = GamePartyList.onSkullChange,
    onWalk         = GamePartyList.onWalk,
  })

  ProtocolGame.unregisterOpcode(ServerOpcodes.ServerOpcodePartyList)

  -- Window

  g_keyboard.unbindKeyDown('Ctrl+P')

  partyTopMenuButton:destroy()
  partyWindow:destroy()

  partyLevelCalculatorWindow:destroy()
  partyLevelCalculatorWindow = nil

  emptyMenuButton = nil
  sortMenuButton = nil
  arrowMenuButton = nil

  lastButtonSwitched = nil

  mouseWidget:destroy()
  mouseWidget = nil

  separator = nil
  partyLabel = nil
  inviteeLabel = nil

  inviteePanel = nil
  partyPanel = nil

  contentsPanel = nil
  partyTopMenuButton = nil
  partyHeader = nil
  partyWindow = nil

  -- Data

  partyList          = { }
  partyListByIndex   = { }
  inviteeList        = { }
  inviteeListByIndex = { }

  _G.GamePartyList = nil
end

function GamePartyList.online()
  GameInterface.setupMiniWindow(partyWindow, partyTopMenuButton)
end

function GamePartyList.offline()
  -- Level Calculator Window
  GamePartyList.partyLevelCalculatorWindowHide()

  GamePartyList.clearList()
end

function GamePartyList.toggle()
  GameInterface.toggleMiniWindow(partyWindow)
end



-- Button

function GamePartyList.getButtonMemberIndex(cid)
  for k, button in ipairs(partyListByIndex) do
    if cid == button.cid then
      return k
    end
  end
  return nil
end

function GamePartyList.getButtonInviteeIndex(cid)
  for k, button in ipairs(inviteeListByIndex) do
    if cid == button.cid then
      return k
    end
  end
  return nil
end

function GamePartyList.add(data, isInvitee)
  if type(data) ~= 'userdata' and type(data) ~= 'table' then
    return
  end

  local cid = getCid(data)

  if not cid then
    return
  end

  -- Invitee list
  if isInvitee then
    -- Already added
    if inviteeList[cid] then
      -- Return: button found, added already
      return inviteeList[cid], false

    -- Found within member list
    elseif partyList[cid] then
      -- Remove this button
      GamePartyList.remove(partyList[cid])
    end

  -- Member list
  elseif not isInvitee then
    -- Already added
    if partyList[cid] then
      -- Return: button found, added already
      return partyList[cid], false

    -- Found within invitee list
    elseif inviteeList[cid] then
      -- Remove this button
      GamePartyList.remove(inviteeList[cid])
    end
  end

  local localPlayer = g_game.getLocalPlayer()

  local button = g_ui.createWidget('PartyButton')
  button:setup(data)

  if cid ~= localPlayer:getId() and not isInvitee and button.creatureTypeId == CreatureTypePlayer then
    button:enableCreatureMinimapWidget()
  end

  -- -- Callback
  -- button.onMouseRelease                               = GamePartyList.onButtonMouseRelease
  -- button:getChildById('positionLabel').onMouseRelease = GamePartyList.onButtonMouseRelease -- Because it has tooltip (phantom false)

  -- Hide widgets that is not updated as being invitee button
  local hiddenWidgetIds = { }
  -- Invitee widgets to hide
  if isInvitee then
    hiddenWidgetIds = { 'healthBar', 'manaBar', 'positionLabel', 'infoIcon', 'pingLabel', 'creatureType', 'skull', 'emblem', 'specialIcon' }
  else
    -- Summon widgets to hide
    if table.contains({ CreatureTypeSummonOwn, CreatureTypeSummonOther }, button.creatureTypeId) then
      hiddenWidgetIds = { 'manaBar', 'pingLabel', 'skull', 'emblem', 'specialIcon' }
    end
  end
  for _, hiddenWidgetId in ipairs(hiddenWidgetIds) do
    local widget = button:getChildById(hiddenWidgetId)
    if widget then
      widget:setVisible(false)
    end
  end

  -- if button.creature == g_game.getFollowingCreature() then
  --   GamePartyList.onFollowingCreatureChange(button)
  -- end

  -- Add to invitee list
  if isInvitee then
    inviteeList[cid] = button
    table.insert(inviteeListByIndex, button)
    inviteePanel:addChild(button)
    button:setHeight(button.inviteeButtonHeight)
    GamePartyList.updateInviteeList()

  -- Add to member list
  else
    partyList[cid] = button
    table.insert(partyListByIndex, button)
    partyPanel:addChild(button)
    button:setHeight(button.memberButtonHeight)
    GamePartyList.updateMemberList()
  end

  return button, true
end

function GamePartyList.remove(data)
  local cid = getCid(data)

  if not cid then
    return
  end

  local localPlayer = g_game.getLocalPlayer()

  -- Left party, so remove it all
  if cid == localPlayer:getId() then
    GamePartyList.clearList()
    return true -- All removed
  end

  local memberIndex  = GamePartyList.getButtonMemberIndex(cid)
  local inviteeIndex = GamePartyList.getButtonInviteeIndex(cid)

  if not memberIndex and not inviteeIndex then
    -- print_traceback('GamePartyList.remove - attempt to remove invalid partyButton')
    return false -- Not found
  end

  -- Member

  if memberIndex then
    local playerTypeId = partyListByIndex[memberIndex].creatureTypeId

    table.remove(partyListByIndex, memberIndex)
    if partyList[cid] then
      if partyList[cid] == lastButtonSwitched then
        lastButtonSwitched = nil
      end

      partyList[cid]:destroy()
      partyList[cid] = nil
    end

    -- Remove summons of player
    if playerTypeId == CreatureTypePlayer then
      -- Find all summons
      for i = #partyListByIndex, 1, -1 do
        -- Found a summon
        if partyListByIndex[i].masterCid == cid then -- masterCid of summon is equals to cid of player

          local summonCid = partyListByIndex[i].cid

          -- Remove summon
          table.remove(partyListByIndex, i)
          if partyList[summonCid] then
            if partyList[summonCid] == lastButtonSwitched then
              lastButtonSwitched = nil
            end

            partyList[summonCid]:destroy()
            partyList[summonCid] = nil
          end
        end
      end
    end
  end

  -- Invitee

  if inviteeIndex then
    table.remove(inviteeListByIndex, inviteeIndex)
    if inviteeList[cid] then
      if inviteeList[cid] == lastButtonSwitched then
        lastButtonSwitched = nil
      end

      inviteeList[cid]:destroy()
      inviteeList[cid] = nil
    end

    GamePartyList.updateInviteeList() -- Necessary to disable invitee widgets when invitee is empty
  end

  return true -- Found and removed
end

-- function GamePartyList.updateButton(button)
--   button:update()

--   if button.isFollowed then
--     if lastButtonSwitched and lastButtonSwitched ~= button then
--       lastButtonSwitched.isFollowed = false
--       GamePartyList.updateButton(lastButtonSwitched)
--     end
--     lastButtonSwitched = button
--   end
-- end

-- function GamePartyList.updateButtons() -- Based on GameBattleList.updateBattleButtons -- Needed?

-- function GamePartyList.onButtonHoverChange(self, hovered) -- Based on GameBattleList.onBattleButtonHoverChange -- todo

function GamePartyList.onButtonMouseRelease(self, mousePosition, mouseButton)
  if mouseWidget.cancelNextRelease then
    mouseWidget.cancelNextRelease = false
    return false
  end

  -- local creature    = g_map.getCreatureById(self.cid) -- can be nil if unknown by client
  -- if mouseButton == MouseLeftButton and g_keyboard.isCtrlPressed() and g_keyboard.isShiftPressed() then
  --   g_game.follow(creature)
  --   return true
  -- end

  local localPlayer = g_game.getLocalPlayer()

  if mouseButton == MouseRightButton and not g_mouse.isPressed(MouseLeftButton) then

    local menu = g_ui.createWidget('PopupMenu')

    -- Player
    if self.creatureTypeId == CreatureTypePlayer then

      -- Local player
      if self.cid == localPlayer:getId() then

        if localPlayer:isPartyMember() then
          if localPlayer:isPartyLeader() then
            if localPlayer:isPartySharedExperienceActive() then
              menu:addOption(tr('Disable shared XP'), function() g_game.partyShareExperience(false) end)
            else
              menu:addOption(tr('Enable shared XP'), function() g_game.partyShareExperience(true) end)
            end
          end
          menu:addOption(tr('Leave party'), function() g_game.partyLeave() end)
        end

      -- Other player
      else

        local localPlayerShield = localPlayer:getShield()
        local creatureShield    = self.shieldId

        if localPlayerShield == ShieldWhiteYellow then
          if creatureShield == ShieldWhiteBlue then
            menu:addOption(tr('Revoke %s\'s invitation', self.name), function() g_game.partyRevokeInvitation(self.cid) end)
          end
        elseif localPlayerShield == ShieldYellow or localPlayerShield == ShieldYellowSharedExp or localPlayerShield == ShieldYellowNoSharedExpBlink or localPlayerShield == ShieldYellowNoSharedExp then
          if creatureShield == ShieldWhiteBlue then
            menu:addOption(tr('Revoke %s\'s invitation', self.name), function() g_game.partyRevokeInvitation(self.cid) end)
          elseif creatureShield == ShieldBlue or creatureShield == ShieldBlueSharedExp or creatureShield == ShieldBlueNoSharedExpBlink or creatureShield == ShieldBlueNoSharedExp then
            menu:addOption(tr('Pass leadership to %s', self.name), function() g_game.partyPassLeadership(self.cid) end)
          end
        end
      end
    end

    menu:addSeparator()

    menu:addOption(tr('Copy name'), function() g_window.setClipboardText(self.name) end)

    menu:display(menuPosition)

    return true
  end

  return false
end

-- function GamePartyList.updateButtonStaticSquare() -- Based on GameBattleList.updateStaticSquare -- Needed?



-- Filtering

function GamePartyList.onClickArrowMenuButton(self)
  local newState = not self:isOn()
  arrowMenuButton:setOn(newState)
  partyHeader:setOn(not newState)
  g_settings.setValue('PartyList', 'filterPanel', newState)
end

function GamePartyList.buttonFilter(button)
  local filterPlayers         = not filterPlayersButton:isOn()
  local filterSummons         = not filterSummonsButton:isOn()
  local filterKnightPlayers   = not filterKnightPlayersButton:isOn()
  local filterPaladinPlayers  = not filterPaladinPlayersButton:isOn()
  local filterArcherPlayers   = not filterArcherPlayersButton:isOn()
  local filterAssassinPlayers = not filterAssassinPlayersButton:isOn()
  local filterWizardPlayers   = not filterWizardPlayersButton:isOn()
  local filterBardPlayers     = not filterBardPlayersButton:isOn()

  local isPlayer = button.creatureTypeId == CreatureTypePlayer

  return  filterSummons and table.contains({ CreatureTypeSummonOwn, CreatureTypeSummonOther }, button.creatureTypeId) or
          isPlayer and (
            filterPlayers or
            filterKnightPlayers and button.vocationId == VocationKnight or
            filterPaladinPlayers and button.vocationId == VocationPaladin or
            filterArcherPlayers and button.vocationId == VocationArcher or
            filterAssassinPlayers and button.vocationId == VocationAssassin or
            filterWizardPlayers and button.vocationId == VocationWizard or
            filterBardPlayers and button.vocationId == VocationBard
          )
end

function GamePartyList.filterButtons()
  for _, _button in ipairs(partyListByIndex) do
    _button:setOn(not GamePartyList.buttonFilter(_button))
  end
end

function GamePartyList.onClickFilterPlayers(self)
  local newState = not self:isOn()
  filterPlayersButton:setOn(newState)
  g_settings.setValue('PartyList', 'filterPlayers', newState)
  GamePartyList.filterButtons()
end

function GamePartyList.onClickFilterSummons(self)
  local newState = not self:isOn()
  filterSummonsButton:setOn(newState)
  g_settings.setValue('PartyList', 'filterSummons', newState)
  GamePartyList.filterButtons()
end

function GamePartyList.onClickFilterKnightPlayers(self)
  local newState = not self:isOn()
  filterKnightPlayersButton:setOn(newState)
  g_settings.setValue('PartyList', 'filterKnightPlayers', newState)
  GamePartyList.filterButtons()
end

function GamePartyList.onClickFilterPaladinPlayers(self)
  local newState = not self:isOn()
  filterPaladinPlayersButton:setOn(newState)
  g_settings.setValue('PartyList', 'filterPaladinPlayers', newState)
  GamePartyList.filterButtons()
end

function GamePartyList.onClickFilterArcherPlayers(self)
  local newState = not self:isOn()
  filterArcherPlayersButton:setOn(newState)
  g_settings.setValue('PartyList', 'filterArcherPlayers', newState)
  GamePartyList.filterButtons()
end

function GamePartyList.onClickFilterAssassinPlayers(self)
  local newState = not self:isOn()
  filterAssassinPlayersButton:setOn(newState)
  g_settings.setValue('PartyList', 'filterAssassinPlayers', newState)
  GamePartyList.filterButtons()
end

function GamePartyList.onClickFilterWizardPlayers(self)
  local newState = not self:isOn()
  filterWizardPlayersButton:setOn(newState)
  g_settings.setValue('PartyList', 'filterWizardPlayers', newState)
  GamePartyList.filterButtons()
end

function GamePartyList.onClickFilterBardPlayers(self)
  local newState = not self:isOn()
  filterBardPlayersButton:setOn(newState)
  g_settings.setValue('PartyList', 'filterBardPlayers', newState)
  GamePartyList.filterButtons()
end



-- Sorting

function GamePartyList.getSortType()
  return g_settings.getValue('PartyList', 'sortType', defaultValues.sortType)
end

function GamePartyList.setSortType(state)
  g_settings.setValue('PartyList', 'sortType', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', SortTypeStr[state] or '', SortOrderStr[GamePartyList.getSortOrder()] or ''))
  GamePartyList.updateMemberList()
end

function GamePartyList.getSortOrder()
  return g_settings.getValue('PartyList', 'sortOrder', defaultValues.sortOrder)
end

function GamePartyList.setSortOrder(state)
  g_settings.setValue('PartyList', 'sortOrder', state)
  sortMenuButton:setTooltip(tr('Sort by: %s (%s)', SortTypeStr[GamePartyList.getSortType()] or '', SortOrderStr[state] or ''))
  GamePartyList.updateMemberList()
end

-- GamePartyList.partyLevelCalculatorWindowShow() -- REMOVE THIS
function GamePartyList.createSortMenu() -- todo
  local menu = g_ui.createWidget('PopupMenu')

  local sortOrder = GamePartyList.getSortOrder()
  local sortType  = GamePartyList.getSortType()

  if sortOrder == SortOrderAscending then
    menu:addOption(tr('%s Order', SortOrderStr[SortOrderDescending]), function() GamePartyList.setSortOrder(SortOrderDescending) end)
  elseif sortOrder == SortOrderDescending then
    menu:addOption(tr('%s Order', SortOrderStr[SortOrderAscending]), function() GamePartyList.setSortOrder(SortOrderAscending) end)
  end

  menu:addSeparator()

  if sortType ~= SortTypeHierarchy then
    menu:addOption(tr('Sort by %s', SortTypeStr[SortTypeHierarchy]), function() GamePartyList.setSortType(SortTypeHierarchy) end)
  end
  if sortType ~= SortTypeAppear then
    menu:addOption(tr('Sort by %s', SortTypeStr[SortTypeAppear]), function() GamePartyList.setSortType(SortTypeAppear) end)
  end
  if sortType ~= SortTypeDistance then
    menu:addOption(tr('Sort by %s', SortTypeStr[SortTypeDistance]), function() GamePartyList.setSortType(SortTypeDistance) end)
  end
  if sortType ~= SortTypeHealth then
    menu:addOption(tr('Sort by %s', SortTypeStr[SortTypeHealth]), function() GamePartyList.setSortType(SortTypeHealth) end)
  end
  if sortType ~= SortTypeMana then
    menu:addOption(tr('Sort by %s', SortTypeStr[SortTypeMana]), function() GamePartyList.setSortType(SortTypeMana) end)
  end
  if sortType ~= SortTypeName then
    menu:addOption(tr('Sort by %s', SortTypeStr[SortTypeName]), function() GamePartyList.setSortType(SortTypeName) end)
  end
  if sortType ~= SortTypePing then
    menu:addOption(tr('Sort by %s', SortTypeStr[SortTypePing]), function() GamePartyList.setSortType(SortTypePing) end)
  end

  menu:addSeparator()

  menu:addOption(tr('Open party level calculator'), function() GamePartyList.partyLevelCalculatorWindowShow() end)

  menu:display()
end

function GamePartyList.sortList()
  local sortFunction

  local sortOrder = GamePartyList.getSortOrder()
  local sortType  = GamePartyList.getSortType()

  if sortOrder == SortOrderAscending then
    -- Ascending - Hierarchy
    if sortType == SortTypeHierarchy then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()
        sortFunction = function(a,b) return ShieldHierarchy[a.shieldId] < ShieldHierarchy[b.shieldId] or ShieldHierarchy[a.shieldId] == ShieldHierarchy[b.shieldId] and getDistanceTo(localPlayerPos, a.position) < getDistanceTo(localPlayerPos, b.position) end
      end

    -- Ascending - Appear
    elseif sortType == SortTypeAppear then
      sortFunction = function(a,b) return a.lastAppear < b.lastAppear end

    -- Ascending - Distance
    elseif sortType == SortTypeDistance then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()
        sortFunction = function(a,b) return getDistanceTo(localPlayerPos, a.position) < getDistanceTo(localPlayerPos, b.position) end
      end

    -- Ascending - Health
    elseif sortType == SortTypeHealth then
      sortFunction = function(a,b) return a.healthPercent < b.healthPercent end

    -- Ascending - Mana
    elseif sortType == SortTypeMana then
      sortFunction = function(a,b) return a.manaPercent < b.manaPercent end

    -- Ascending - Name
    elseif sortType == SortTypeName then
      sortFunction = function(a,b) return a:getCreatureName() < b:getCreatureName() end

    -- Ascending - Ping
    elseif sortType == SortTypePing then
      sortFunction = function(a,b) return a.ping < b.ping end
    end

  elseif sortOrder == SortOrderDescending then
    -- Descending - Hierarchy
    if sortType == SortTypeHierarchy then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()
        sortFunction = function(a,b) return ShieldHierarchy[a.shieldId] > ShieldHierarchy[b.shieldId] or ShieldHierarchy[a.shieldId] == ShieldHierarchy[b.shieldId] and getDistanceTo(localPlayerPos, a.position) > getDistanceTo(localPlayerPos, b.position) end
      end

    -- Descending - Appear
    elseif sortType == SortTypeAppear then
      sortFunction = function(a,b) return a.lastAppear > b.lastAppear end

    -- Descending - Distance
    elseif sortType == SortTypeDistance then
      local localPlayer = g_game.getLocalPlayer()
      if localPlayer then
        local localPlayerPos = localPlayer:getPosition()
        sortFunction = function(a,b) return getDistanceTo(localPlayerPos, a.position) > getDistanceTo(localPlayerPos, b.position) end
      end

    -- Descending - Health
    elseif sortType == SortTypeHealth then
      sortFunction = function(a,b) return a.healthPercent > b.healthPercent end

    -- Descending - Mana
    elseif sortType == SortTypeMana then
      sortFunction = function(a,b) return a.manaPercent > b.manaPercent end

    -- Descending - Name
    elseif sortType == SortTypeName then
      sortFunction = function(a,b) return a:getCreatureName() > b:getCreatureName() end

    -- Descending - Name
    elseif sortType == SortTypePing then
      sortFunction = function(a,b) return a.ping > b.ping end
    end
  end

  if sortFunction then
    table.sort(partyListByIndex, sortFunction)
  end
end

function GamePartyList.updateMemberList()
  GamePartyList.sortList()
  for i = 1, #partyListByIndex do
    partyPanel:moveChildToIndex(partyListByIndex[i], i)
  end
  GamePartyList.filterButtons()
end

function GamePartyList.updateInviteeList()
  local enable = #inviteeListByIndex > 0

  for i = 1, #inviteeListByIndex do
    inviteePanel:moveChildToIndex(inviteeListByIndex[i], i)
  end

  -- Enable all buttons (if they exists)
  for _, _button in ipairs(inviteeListByIndex) do
    _button:setOn(true)
  end

  -- Widgets
  inviteeLabel:setOn(enable)
  inviteePanel:setOn(enable)
  separator:setOn(enable)
  partyLabel:setOn(enable)
end

function GamePartyList.clearList()
  lastButtonSwitched = nil
  partyList          = { }
  partyListByIndex   = { }
  inviteeList        = { }
  inviteeListByIndex = { }

  partyPanel:destroyChildren()
  inviteePanel:destroyChildren()

  GamePartyList.updateInviteeList() -- Necessary to disable invitee widgets when invitee is empty

  emptyMenuButton:setTooltip(tr('You are not in party.'))
end

function GamePartyList.refreshList()
  GamePartyList.clearList()

  -- todo: Request data again
end



-- Events

-- function GamePartyList.onFollowingCreatureChange(data)
--   local cid      = getCid(data)
--   local creature = cid and g_map.getCreatureById(cid) or nil
--   local button   = creature and partyList[cid] or lastButtonSwitched

--   if button then
--     button.isFollowed = creature and true or false
--     GamePartyList.updateButton(button)
--   end
-- end

function GamePartyList.tryUpdateMemberList(button, pos, oldPos)
  local posCheck = g_clock.millis()
  local diffTime = posCheck - lastUpdateCheck

  if (pos and oldPos and pos.z ~= oldPos.z and button and button.cid == g_game.getLocalPlayer():getId()) or diffTime > TimedUpdateDelay then
    GamePartyList.updateMemberList()

    lastUpdateCheck = posCheck
  end
end

function GamePartyList.onWalk(creature, oldPosition, newPosition)
  -- Update local player position

  local localPlayer = g_game.getLocalPlayer()

  if creature ~= localPlayer then
    return
  end

  local memberButton = partyList[localPlayer:getId()]
  if not memberButton then
    return
  end

  memberButton:updatePosition(newPosition)

  if table.contains({ SortTypeDistance, SortTypeHierarchy }, GamePartyList.getSortType()) then
    GamePartyList.tryUpdateMemberList(memberButton, newPosition, oldPosition)
  end
end

function GamePartyList.updateLocalPlayerPing(ping)
  -- Update local player ping

  local localPlayer = g_game.getLocalPlayer()

  local memberButton = partyList[localPlayer:getId()]
  if not memberButton then
    return
  end

  memberButton:updatePing(ping)

  if GamePartyList.getSortType() == SortTypePing then
    GamePartyList.updateMemberList()
  end
end

-- Server to client

local function getPartyButton(msg, button, isInvitee)
  local protocolGame = g_game.getProtocolGame()

  button.cid      = msg:getU32()
  button.outfit   = protocolGame:getOutfit(msg)
  button.name     = g_game.formatCreatureName(msg:getString())
  button.nickname = msg:getString()

  button.creatureTypeId = msg:getU8()

  if button.creatureTypeId == CreatureTypePlayer then
    button.shieldId = msg:getU8()
  elseif button.creatureTypeId == CreatureTypeSummonOwn or button.creatureTypeId == CreatureTypeSummonOther then
    button.masterCid = msg:getU32()
  end

  if not isInvitee then
    button.position       = protocolGame:getPosition(msg)
    button.healthPercent  = msg:getU8()
    button.skullId        = msg:getU8()

    if button.creatureTypeId == CreatureTypePlayer then
      button.vocationId    = msg:getU16()
      button.manaPercent   = msg:getU8()
      button.emblemId      = msg:getU8()
      button.specialIconId = msg:getU8()
    end
  end
end

local serverSignals = { }

serverSignals[PARTYLIST_SERVERSIGNAL_CREATE] = function(msg)
  serverSignals[PARTYLIST_SERVERSIGNAL_JOIN](msg)
end

serverSignals[PARTYLIST_SERVERSIGNAL_JOIN] = function(msg)
  local button    = { }
  local isInvitee = false

  -- Add member as button to local player
  getPartyButton(msg, button, isInvitee)
  GamePartyList.add(button, isInvitee)
end

serverSignals[PARTYLIST_SERVERSIGNAL_LEAVE] = function(msg)
  local cid = msg:getU32()

  -- Remove player button of cid only from local player
  GamePartyList.remove(cid)
end

serverSignals[PARTYLIST_SERVERSIGNAL_DISBAND] = function(msg)
  GamePartyList.clearList()
end

serverSignals[PARTYLIST_SERVERSIGNAL_ADDINVITE] = function(msg)
  local button    = { }
  local isInvitee = true

  -- Add invitee as button to leader (only leader can see invitees)
  getPartyButton(msg, button, isInvitee)
  GamePartyList.add(button, isInvitee)
end

serverSignals[PARTYLIST_SERVERSIGNAL_REMOVEINVITE] = function(msg)
  local cid = msg:getU32()

  -- Remove invitee from leader (only leader can see invitees)
  GamePartyList.remove(cid)
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDCREATUREOUTFIT] = function(msg)
  local protocolGame = g_game.getProtocolGame()

  local memberCid    = msg:getU32()
  local memberOutfit = protocolGame:getOutfit(msg)

  local memberButton = partyList[memberCid]

  if not memberButton then
    return
  end

  memberButton:updateCreature(memberOutfit)
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDCREATURENICKNAME] = function(msg)
  local memberCid      = msg:getU32()
  local memberNickname = msg:getString()

  local memberButton = partyList[memberCid]

  if not memberButton then
    return
  end

  memberButton:updateLabelText(memberNickname)

  if GamePartyList.getSortType() == SortTypeName then
    GamePartyList.updateMemberList()
  end
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDCREATURESHIELD] = function(msg)
  local memberCid      = msg:getU32()
  local memberShieldId = msg:getU8()

  local memberButton = partyList[memberCid]

  if not memberButton then
    return
  end

  memberButton:updateShield(memberShieldId)

  if GamePartyList.getSortType() == SortTypeHierarchy then
    GamePartyList.updateMemberList()
  end
end

-- Never happens since skulls are always green on members of party
serverSignals[PARTYLIST_SERVERSIGNAL_SENDCREATURESKULL] = function(msg)
  local memberCid     = msg:getU32()
  local memberSkullId = msg:getU8()

  local memberButton = partyList[memberCid]

  if not memberButton then
    return
  end

  memberButton:updateSkull(memberSkullId)
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDCREATURESPECIALICON] = function(msg)
  local memberCid           = msg:getU32()
  local memberSpecialIconId = msg:getU8()

  local memberButton = partyList[memberCid]

  if not memberButton then
    return
  end

  memberButton:updateSpecialIcon(memberSpecialIconId)
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDCREATURESPOSITION] = function(msg)
  local protocolGame = g_game.getProtocolGame()
  local membersCount = msg:getU8()
  local sortType     = GamePartyList.getSortType()

  for i = 1, membersCount do
    local memberCid      = msg:getU32()
    local memberPosition = protocolGame:getPosition(msg)

    local memberButton = partyList[memberCid]

    if memberButton then
      local oldPosition = memberButton.position

      memberButton:updatePosition(memberPosition)

      if table.contains({ SortTypeDistance, SortTypeHierarchy }, sortType) then
        GamePartyList.tryUpdateMemberList(memberButton, memberPosition, oldPosition)
      end
    end
  end
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDCREATUREHEALTHPERCENT] = function(msg)
  local memberCid           = msg:getU32()
  local memberHealthPercent = msg:getU8()

  local memberButton = partyList[memberCid]

  if not memberButton then
    return
  end

  memberButton:updateHealthPercent(memberHealthPercent)

  if GamePartyList.getSortType() == SortTypeHealth then
    GamePartyList.updateMemberList()
  end
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDCREATUREMANAPERCENT] = function(msg)
  local memberCid         = msg:getU32()
  local memberManaPercent = msg:getU8()

  local memberButton = partyList[memberCid]

  if not memberButton then
    return
  end

  memberButton:updateManaPercent(memberManaPercent)

  if GamePartyList.getSortType() == SortTypeMana then
    GamePartyList.updateMemberList()
  end
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDPLAYERSPING] = function(msg)
  local membersCount = msg:getU8()

  for i = 1, membersCount do
    local memberCid  = msg:getU32()
    local memberPing = msg:getU64()

    if memberPing == 2^64 - 1 then -- maximum value of uint64_t
      memberPing = -1 -- any negative value
    end

    local memberButton = partyList[memberCid]

    if memberButton then
      memberButton:updatePing(memberPing)
    end
  end

  if GamePartyList.getSortType() == SortTypePing then
    GamePartyList.updateMemberList()
  end
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDVOCATIONID] = function(msg)
  local memberCid        = msg:getU32()
  local memberVocationId = msg:getU8()

  local memberButton = partyList[memberCid]
  if not memberButton then
    return
  end

  memberButton:updateVocation(memberVocationId)
end

serverSignals[PARTYLIST_SERVERSIGNAL_SENDEXTRAEXPERIENCETOOLTIP] = function(msg)
  local extraExperienceTooltip = msg:getString()
  local extraExperienceValue   = msg:getDouble()

  emptyMenuButton:setTooltip(extraExperienceValue > 0 and tr(extraExperienceTooltip, extraExperienceValue) or tr('You have no partners in your party yet.'))
end

function GamePartyList.parsePartyList(protocol, msg)
  if not g_game.getProtocolGame() then
    return
  end

  local serverSignalId = msg:getU8()
  local serverSignal   = serverSignals[serverSignalId]

  if not serverSignal then
    print_traceback(string.format('GamePartyList.parsePartyList - attempt to call an unknown server signal of id %d', serverSignalId))
    return
  end

  serverSignal(msg)
end

-- Client to server

local clientSignals = { }

-- -- Use GamePartyList.sendPartyList(GamePartyList.m.PARTYLIST_CLIENTSIGNAL_REQUESTPOSITIONS) to send it
-- clientSignals[PARTYLIST_CLIENTSIGNAL_REQUESTPOSITIONS] = function(params) -- Example
--   local protocolGame = g_game.getProtocolGame()
--   if not protocolGame then
--     return
--   end

--   local msg = OutputMessage.create()
--   msg:addU8(ClientOpcodes.ClientOpcodePartyList)
--   msg:addU8(PARTYLIST_CLIENTSIGNAL_REQUESTPOSITIONS) -- U8 for opcode, U16 for extended opcode
--   msg:addDouble(107.56789012345, 4) -- 107.5678
--   protocolGame:send(msg)
-- end

function GamePartyList.sendPartyList(clientSignalId, params)
  if not g_game.getProtocolGame() then
    return
  end

  local clientSignal = clientSignals[clientSignalId]

  if not clientSignal then
    print_traceback(string.format('GamePartyList.sendPartyList - attempt to call an unknown client signal of id %d', clientSignalId))
    return
  end

  clientSignal(params)
end





-- Party Level Calculator Window

function GamePartyList.partyLevelCalculatorWindowShow()
  partyLevelCalculatorWindow:show()
  partyLevelCalculatorWindow:focus()
end

function GamePartyList.partyLevelCalculatorWindowHide()
  partyLevelCalculatorWindow:hide()
  GamePartyList.partyLevelCalculatorWindowClear()
end

function GamePartyList.partyLevelCalculatorWindowClear()
  levelTextEdit:setText('')
  GamePartyList.onLevelTextEditChange(levelLabel)
end

function GamePartyList.onLevelTextEditChange(self)
  if not levelLabel then -- onLevelTextEditChange executes even when levelLabel is nil
    return
  end

  local text   = self:getText()
  local number = tonumber(text)

  -- If not integer
  if text ~= '' and (text:match("[^0-9]+") or not number) then
    self:setText('')
  end

  if number and number > 0 then
    local minLevel = math.ceil((number * 2) / 3)
    local maxLevel = math.floor((number * 3) / 2)
    levelLabel:setText(tr('The required level range to be able to enable the shared experience in party is between %d and %d.', minLevel, maxLevel))
  else
    levelLabel:setText(tr('Type a level.'))
  end
end
