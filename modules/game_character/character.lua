_G.GameCharacter = { }



outfitCreatureBox = nil



healthBar = nil
manaBar = nil
experienceBar = nil
healthBarValueLabel = nil
manaBarValueLabel = nil
experienceBarValueLabel = nil
capLabel = nil



InventorySlotStyles =
{
  [InventorySlotHead] = "HeadSlot",
  [InventorySlotNeck] = "NeckSlot",
  [InventorySlotBack] = "BackSlot",
  [InventorySlotBody] = "BodySlot",
  [InventorySlotRight] = "RightSlot",
  [InventorySlotLeft] = "LeftSlot",
  [InventorySlotLeg] = "LegSlot",
  [InventorySlotFeet] = "FeetSlot",
  [InventorySlotFinger] = "FingerSlot",
  [InventorySlotAmmo] = "AmmoSlot"
}

inventoryTopMenuButton = nil
inventoryWindow = nil
inventoryHeader = nil
inventoryFooter = nil



-- Combat controls
fightOffensiveBox = nil
fightBalancedBox = nil
fightDefensiveBox = nil
chaseModeButton = nil
safeFightButton = nil
mountButton = nil
fightModeRadioGroup = nil



function GameCharacter.init()
  -- Alias
  GameCharacter.m = modules.game_character

  connect(LocalPlayer, {
    onChangeOutfit = GameCharacter.onChangeOutfit,

    -- Health info
    onHealthChange       = GameCharacter.onHealthChange,
    onManaChange         = GameCharacter.onManaChange,
    onLevelChange        = GameCharacter.onLevelChange,
    onFreeCapacityChange = GameCharacter.onFreeCapacityChange,

    -- Inventory
    onInventoryChange = GameCharacter.onInventoryChange,
    onBlessingsChange = GameCharacter.onBlessingsChange,

    -- Combat controls
    onOutfitChange = GameCharacter.onOutfitChange
  })

  connect(g_game, {
    -- Inventory / Combat controls
    onGameStart = GameCharacter.online,

    -- Health info / Combat controls
    onGameEnd = GameCharacter.offline,

    -- Combat controls
    onChaseModeChange = GameCharacter.update,
    onSafeFightChange = GameCharacter.update,
    onFightModeChange = GameCharacter.update,
    onWalk            = GameCharacter.check,
    onAutoWalk        = GameCharacter.check
  })

  g_keyboard.bindKeyDown('Ctrl+I', GameCharacter.toggle)


  inventoryWindow = g_ui.loadUI('character')
  inventoryHeader = inventoryWindow:getChildById('miniWindowHeader')
  inventoryFooter = inventoryWindow:getChildById('miniWindowFooter')
  inventoryTopMenuButton = ClientTopMenu.addRightGameToggleButton('inventoryTopMenuButton', tr('Character') .. ' (Ctrl+I)', '/images/ui/top_menu/healthinfo', GameCharacter.toggle)

  inventoryWindow.topMenuButton = inventoryTopMenuButton
  inventoryWindow:disableResize()

  local contentsPanel = inventoryWindow:getChildById('contentsPanel')

  local ballButton = inventoryWindow:getChildById('ballButton')
  inventoryWindow.onMinimize = function (self)
    ballButton:setTooltip('Show more')
  end
  inventoryWindow.onMaximize = function (self)
    local headSlot = contentsPanel:getChildById('slot1')
    if headSlot:isVisible() then
      ballButton:setTooltip('Show less')
    end
  end

  outfitCreatureBox = contentsPanel:getChildById('outfitCreatureBox')

  -- Health info
  healthBar               = inventoryHeader:getChildById('healthBar')
  manaBar                 = inventoryHeader:getChildById('manaBar')
  experienceBar           = inventoryHeader:getChildById('experienceBar')
  healthBarValueLabel     = inventoryHeader:getChildById('healthBarValueLabel')
  manaBarValueLabel       = inventoryHeader:getChildById('manaBarValueLabel')
  experienceBarValueLabel = inventoryHeader:getChildById('experienceBarValueLabel')
  capLabel                = inventoryFooter:getChildById('capLabel')

  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    GameCharacter.onHealthChange(localPlayer, localPlayer:getHealth(), localPlayer:getMaxHealth())
    GameCharacter.onManaChange(localPlayer, localPlayer:getMana(), localPlayer:getMaxMana())
    GameCharacter.onLevelChange(localPlayer, localPlayer:getLevel(), localPlayer:getLevelPercent())
    GameCharacter.onFreeCapacityChange(localPlayer, localPlayer:getFreeCapacity())
  end

  local combatControls = contentsPanel:getChildById('combatControls')

  -- Combat controls
  fightOffensiveBox = combatControls:getChildById('fightOffensiveBox')
  fightBalancedBox = combatControls:getChildById('fightBalancedBox')
  fightDefensiveBox = combatControls:getChildById('fightDefensiveBox')
  chaseModeButton = combatControls:getChildById('chaseModeBox')
  safeFightButton = combatControls:getChildById('safeFightBox')
  mountButton = combatControls:getChildById('mountButton')
  mountButton.onClick = GameCharacter.onMountButtonClick

  -- Combat controls
  fightModeRadioGroup = UIRadioGroup.create()
  fightModeRadioGroup:addWidget(fightOffensiveBox)
  fightModeRadioGroup:addWidget(fightBalancedBox)
  fightModeRadioGroup:addWidget(fightDefensiveBox)

  -- Combat controls
  connect(chaseModeButton, {
    onCheckChange = GameCharacter.onSetChaseMode
  })
  connect(safeFightButton, {
    onCheckChange = GameCharacter.onSetSafeFight
  })
  connect(fightModeRadioGroup, {
    onSelectionChange = GameCharacter.onSetFightMode
  })

  GameInterface.setupMiniWindow(inventoryWindow, inventoryTopMenuButton)

  GameCharacter.online()
end

function GameCharacter.terminate()
  if g_game.isOnline() then
    GameCharacter.offline() -- CHECK
  end

  -- Combat controls
  disconnect(chaseModeButton, {
    onCheckChange = GameCharacter.onSetChaseMode
  })
  disconnect(safeFightButton, {
    onCheckChange = GameCharacter.onSetSafeFight
  })
  disconnect(fightModeRadioGroup, {
    onSelectionChange = GameCharacter.onSetFightMode
  })

  disconnect(LocalPlayer, {
    onChangeOutfit = GameCharacter.onChangeOutfit,

    -- Health info
    onHealthChange       = GameCharacter.onHealthChange,
    onManaChange         = GameCharacter.onManaChange,
    onLevelChange        = GameCharacter.onLevelChange,
    onFreeCapacityChange = GameCharacter.onFreeCapacityChange,

    -- Inventory
    onInventoryChange = GameCharacter.onInventoryChange,
    onBlessingsChange = GameCharacter.onBlessingsChange,

    -- Combat controls
    onOutfitChange = GameCharacter.onOutfitChange
  })

  disconnect(g_game, {
    -- Inventory / Combat controls
    onGameStart = GameCharacter.online,

    -- Health info / Combat controls
    onGameEnd = GameCharacter.offline,

    -- Combat controls
    onChaseModeChange = GameCharacter.update,
    onSafeFightChange = GameCharacter.update,
    onFightModeChange = GameCharacter.update,
    onWalk            = GameCharacter.check,
    onAutoWalk        = GameCharacter.check
  })

  g_keyboard.unbindKeyDown('Ctrl+I')

  -- Combat controls
  fightOffensiveBox:destroy()
  fightBalancedBox:destroy()
  fightDefensiveBox:destroy()
  chaseModeButton:destroy()
  safeFightButton:destroy()
  mountButton:destroy()
  fightModeRadioGroup:destroy()
  fightOffensiveBox = nil
  fightBalancedBox = nil
  fightDefensiveBox = nil
  chaseModeButton = nil
  safeFightButton = nil
  mountButton = nil
  fightModeRadioGroup = nil

  outfitCreatureBox:destroy()
  outfitCreatureBox = nil

  -- Health info
  healthBar:destroy()
  manaBar:destroy()
  experienceBar:destroy()
  healthBarValueLabel:destroy()
  manaBarValueLabel:destroy()
  experienceBarValueLabel:destroy()
  capLabel:destroy()
  healthBar = nil
  manaBar = nil
  experienceBar = nil
  healthBarValueLabel = nil
  manaBarValueLabel = nil
  experienceBarValueLabel = nil
  capLabel = nil

  inventoryTopMenuButton:destroy()
  inventoryTopMenuButton = nil
  inventoryWindow:destroy()
  inventoryWindow = nil

  inventoryFooter = nil

  _G.GameCharacter = nil
end





-- Combat controls

function GameCharacter.update()
  local chaseMode = g_game.getChaseMode()
  chaseModeButton:setChecked(chaseMode == ChaseOpponent)

  local safeFight = g_game.isSafeFight()
  safeFightButton:setChecked(not safeFight)

  local fightMode = g_game.getFightMode()
  if fightMode == FightOffensive then
    fightModeRadioGroup:selectWidget(fightOffensiveBox)
  elseif fightMode == FightBalanced then
    fightModeRadioGroup:selectWidget(fightBalancedBox)
  else
    fightModeRadioGroup:selectWidget(fightDefensiveBox)
  end
end

function GameCharacter.check()
  if ClientOptions.getOption('autoChaseOverride') then
    if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
      g_game.setChaseMode(false, DontChase)
    end
  end
end

function GameCharacter.onSetFightMode(self, selectedFightButton)
  if selectedFightButton == nil then
    return
  end

  local buttonId = selectedFightButton:getId()
  local fightMode
  if buttonId == 'fightOffensiveBox' then
    fightMode = FightOffensive
  elseif buttonId == 'fightBalancedBox' then
    fightMode = FightBalanced
  else
    fightMode = FightDefensive
  end
  g_game.setFightMode(false, fightMode)

  if g_game.isOnline() then
    scheduleEvent(function()
      if modules.game_battlelist then
        GameBattleList.updateBattleButtons()
      end
    end, 0)
  end
end

function GameCharacter.onSetChaseMode(self, checked)
  local chaseMode
  if checked then
    chaseMode = ChaseOpponent
  else
    chaseMode = DontChase
  end
  g_game.setChaseMode(false, chaseMode)
end

function GameCharacter.onMountButtonClick(self, mousePos)
  local player = g_game.getLocalPlayer()
  if player then
    player:toggleMount()
  end
end

function GameCharacter.onSetSafeFight(self, checked)
  g_game.setSafeFight(false, not checked)
end

function GameCharacter.onOutfitChange(localPlayer, outfit, oldOutfit)
  if outfit.mount == oldOutfit.mount then
    return
  end

  mountButton:setChecked(outfit.mount ~= nil and outfit.mount > 0)
end





-- Inventory

function GameCharacter.toggleAdventurerStyle(hasBlessing)
  for slot = InventorySlotFirst, InventorySlotLast do
    local itemWidget = inventoryWindow:getChildById('contentsPanel'):getChildById('slot' .. slot)
    if itemWidget then
      itemWidget:setOn(hasBlessing)
    end
  end
end

function GameCharacter.toggle()
  GameInterface.toggleMiniWindow(inventoryWindow)
end

function GameCharacter.onInventoryChange(player, slot, item, oldItem)
  if slot > InventorySlotAmmo then
    return
  end

  local itemWidget = inventoryWindow:getChildById('contentsPanel'):getChildById('slot' .. slot)
  if item then
    itemWidget:setStyle('InventoryItem')
    itemWidget:setItem(item)
  else
    itemWidget:setStyle(InventorySlotStyles[slot])
    itemWidget:setItem(nil)
  end
end

function GameCharacter.onBlessingsChange(player, blessings, oldBlessings)
  local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)
  if hasAdventurerBlessing ~= Bit.hasBit(oldBlessings, Blessings.Adventurer) then
    GameCharacter.toggleAdventurerStyle(hasAdventurerBlessing)
  end
end





function GameCharacter.updateOutfitCreatureBox(creature)
  outfitCreatureBox:setCreature(creature)
end

function GameCharacter.onChangeOutfit(outfit)
  GameCharacter.updateOutfitCreatureBox(g_game.getLocalPlayer())
end

function GameCharacter.onHealthChange(localPlayer, health, maxHealth)
  healthBar:setValue(health, 0, maxHealth)
  healthBarValueLabel:setText(health .. ' / ' .. maxHealth)
  healthBarValueLabel:setTooltip(tr('Your character health is %d out of %d', health, maxHealth))
end

function GameCharacter.onManaChange(localPlayer, mana, maxMana)
  manaBar:setValue(mana, 0, maxMana)
  manaBarValueLabel:setText(mana .. ' / ' .. maxMana)
  manaBarValueLabel:setTooltip(tr('Your character mana is %d out of %d', mana, maxMana))
end

function GameCharacter.onLevelChange(localPlayer, level, levelPercent, oldLevel, oldLevelPercent)
  experienceBar:setPercent(levelPercent)
  experienceBarValueLabel:setText(levelPercent .. '%')
  experienceBarValueLabel:setTooltip(getExperienceTooltipText(localPlayer, level, levelPercent))
end

function GameCharacter.onFreeCapacityChange(player, freeCapacity)
  capLabel:setText(string.format('%s: %.2f oz', tr('Cap'), freeCapacity))
end





function GameCharacter.online()
  GameInterface.setupMiniWindow(inventoryWindow, inventoryTopMenuButton)



  local player = g_game.getLocalPlayer()

  GameCharacter.updateOutfitCreatureBox(player)



  -- Inventory

  for i = InventorySlotFirst, InventorySlotAmmo do
    if g_game.isOnline() then
      GameCharacter.onInventoryChange(player, i, player:getInventoryItem(i))
    else
      GameCharacter.onInventoryChange(player, i, nil)
    end
    GameCharacter.toggleAdventurerStyle(player and Bit.hasBit(player:getBlessings(), Blessings.Adventurer) or false)
  end



  -- Combat controls

  if player then
    local settings = Client.getPlayerSettings()
    local lastCombatControls = settings:getNode('lastCombatControls') or {}

    g_game.setChaseMode(true, lastCombatControls.chaseMode)
    g_game.setSafeFight(true, lastCombatControls.safeFight)
    g_game.setFightMode(true, lastCombatControls.fightMode)

    if lastCombatControls.pvpMode then
      g_game.setPVPMode(true, lastCombatControls.pvpMode)
    end

    if g_game.getFeature(GamePlayerMounts) then
      mountButton:setVisible(true)
      mountButton:setChecked(player:isMounted())
    else
      mountButton:setVisible(false)
    end
  end

  GameCharacter.update()
end

function GameCharacter.offline()
  -- Combat controls

  local settings = Client.getPlayerSettings()
  local lastCombatControls = settings:getNode('lastCombatControls') or {}

  local player = g_game.getLocalPlayer()
  if player then
    lastCombatControls = {
      chaseMode = g_game.getChaseMode(),
      safeFight = g_game.isSafeFight(),
      fightMode = g_game.getFightMode()
    }

    if g_game.getFeature(GamePVPMode) then
      lastCombatControls.pvpMode = g_game.getPVPMode()
    end

    -- Save last combat control settings
    settings:setNode('lastCombatControls', lastCombatControls)
    settings:save()
  end
end

function GameCharacter.showMoreInfo(bool) -- true = Show more; false = Show less; nil = Default
  if inventoryWindow:getSettings('minimized') then
    inventoryWindow:maximize(false)
    return
  end

  local contentsPanel = inventoryWindow:getChildById('contentsPanel')

  local hide     = false
  local headSlot = contentsPanel:getChildById('slot1')
  if bool ~= nil then
    hide = bool
  else
    hide = not headSlot:isVisible()
  end

  headSlot:setVisible(hide)
  contentsPanel:getChildById('slot4'):setVisible(hide) -- Body
  contentsPanel:getChildById('slot7'):setVisible(hide) -- Legs
  contentsPanel:getChildById('slot8'):setVisible(hide) -- Feet
  contentsPanel:getChildById('slot2'):setVisible(hide) -- Neck
  contentsPanel:getChildById('slot6'):setVisible(hide) -- Left Hand
  contentsPanel:getChildById('slot9'):setVisible(hide) -- Ring
  contentsPanel:getChildById('slot3'):setVisible(hide) -- Backpack
  contentsPanel:getChildById('slot5'):setVisible(hide) -- Right Hand
  contentsPanel:getChildById('slot10'):setVisible(hide) -- Ammo

  contentsPanel:getChildById('combatControls'):setVisible(hide)

  if outfitCreatureBox then
    outfitCreatureBox:setVisible(hide)
  end

  local ballButton = inventoryWindow:getChildById('ballButton')
  if hide then
    inventoryWindow:setHeight(258)

    if ballButton then
      ballButton:setTooltip('Show less')
    end
  else
    inventoryWindow:setHeight(94)

    if ballButton then
      ballButton:setTooltip('Show more')
    end
  end
end

function GameCharacter.onMiniWindowBallButton()
  GameCharacter.showMoreInfo()
end
