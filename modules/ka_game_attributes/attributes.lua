_G.GameAttributes = { }



attributeWindow = nil
attributeFooter = nil
attributeTopMenuButton = nil

attackAttributeAddButton    = nil
defenseAttributeAddButton   = nil
willPowerAttributeAddButton = nil
healthAttributeAddButton    = nil
manaAttributeAddButton      = nil
agilityAttributeAddButton   = nil
dodgeAttributeAddButton     = nil
walkingAttributeAddButton   = nil
luckAttributeAddButton      = nil

attackAttributeLabel    = nil
defenseAttributeLabel   = nil
willPowerAttributeLabel = nil
healthAttributeLabel    = nil
manaAttributeLabel      = nil
agilityAttributeLabel   = nil
dodgeAttributeLabel     = nil
walkingAttributeLabel   = nil
luckAttributeLabel      = nil

attackAttributeActLabel    = nil
defenseAttributeActLabel   = nil
willPowerAttributeActLabel = nil
healthAttributeActLabel    = nil
manaAttributeActLabel      = nil
agilityAttributeActLabel   = nil
dodgeAttributeActLabel     = nil
walkingAttributeActLabel   = nil
luckAttributeActLabel      = nil

availablePointsLabel = nil
pointsCostLabel      = nil

ATTRIBUTE_NONE      = 0
ATTRIBUTE_ATTACK    = 1
ATTRIBUTE_DEFENSE   = 2
ATTRIBUTE_WILLPOWER = 3
ATTRIBUTE_HEALTH    = 4
ATTRIBUTE_MANA      = 5
ATTRIBUTE_AGILITY   = 6 -- Limited to 100 points
ATTRIBUTE_DODGE     = 7 -- Limited to 100 points
ATTRIBUTE_WALKING   = 8 -- Limited to 100 points
ATTRIBUTE_LUCK      = 9 -- Limited to 100 points
ATTRIBUTE_FIRST     = ATTRIBUTE_ATTACK
ATTRIBUTE_LAST      = ATTRIBUTE_LUCK

attributeLabel    = nil
attributeActLabel = nil

local attribute_flag_updateList = -1

local _availablePoints = 0



function GameAttributes.init()
  -- Alias
  GameAttributes.m = modules.ka_game_attributes

  g_keyboard.bindKeyDown('Ctrl+Shift+U', GameAttributes.toggle)

  attributeWindow = g_ui.loadUI('attributes')
  attributeFooter = attributeWindow:getChildById('miniWindowFooter')
  attributeTopMenuButton = ClientTopMenu.addRightGameToggleButton('attributeTopMenuButton', tr('Attributes') .. ' (Ctrl+Shift+U)', '/images/ui/top_menu/attributes', GameAttributes.toggle)

  attributeWindow.topMenuButton = attributeTopMenuButton
  attributeWindow:disableResize()

  local contentsPanel = attributeWindow:getChildById('contentsPanel')

  attackAttributeAddButton    = contentsPanel:getChildById('attackAttributeAddButton')
  defenseAttributeAddButton   = contentsPanel:getChildById('defenseAttributeAddButton')
  willPowerAttributeAddButton = contentsPanel:getChildById('willPowerAttributeAddButton')
  healthAttributeAddButton    = contentsPanel:getChildById('healthAttributeAddButton')
  manaAttributeAddButton      = contentsPanel:getChildById('manaAttributeAddButton')
  agilityAttributeAddButton   = contentsPanel:getChildById('agilityAttributeAddButton')
  dodgeAttributeAddButton     = contentsPanel:getChildById('dodgeAttributeAddButton')
  walkingAttributeAddButton   = contentsPanel:getChildById('walkingAttributeAddButton')
  luckAttributeAddButton      = contentsPanel:getChildById('luckAttributeAddButton')

  attackAttributeLabel    = contentsPanel:getChildById('attackAttributeLabel')
  defenseAttributeLabel   = contentsPanel:getChildById('defenseAttributeLabel')
  willPowerAttributeLabel = contentsPanel:getChildById('willPowerAttributeLabel')
  healthAttributeLabel    = contentsPanel:getChildById('healthAttributeLabel')
  manaAttributeLabel      = contentsPanel:getChildById('manaAttributeLabel')
  agilityAttributeLabel   = contentsPanel:getChildById('agilityAttributeLabel')
  dodgeAttributeLabel     = contentsPanel:getChildById('dodgeAttributeLabel')
  walkingAttributeLabel   = contentsPanel:getChildById('walkingAttributeLabel')
  luckAttributeLabel      = contentsPanel:getChildById('luckAttributeLabel')

  attackAttributeActLabel    = contentsPanel:getChildById('attackAttributeActLabel')
  defenseAttributeActLabel   = contentsPanel:getChildById('defenseAttributeActLabel')
  willPowerAttributeActLabel = contentsPanel:getChildById('willPowerAttributeActLabel')
  healthAttributeActLabel    = contentsPanel:getChildById('healthAttributeActLabel')
  manaAttributeActLabel      = contentsPanel:getChildById('manaAttributeActLabel')
  agilityAttributeActLabel   = contentsPanel:getChildById('agilityAttributeActLabel')
  dodgeAttributeActLabel     = contentsPanel:getChildById('dodgeAttributeActLabel')
  walkingAttributeActLabel   = contentsPanel:getChildById('walkingAttributeActLabel')
  luckAttributeActLabel      = contentsPanel:getChildById('luckAttributeActLabel')

  availablePointsLabel = attributeFooter:getChildById('availablePointsLabel')
  pointsCostLabel      = attributeFooter:getChildById('pointsCostLabel')

  attributeLabel =
  {
    [ATTRIBUTE_ATTACK]    = attackAttributeLabel,
    [ATTRIBUTE_DEFENSE]   = defenseAttributeLabel,
    [ATTRIBUTE_WILLPOWER] = willPowerAttributeLabel,
    [ATTRIBUTE_HEALTH]    = healthAttributeLabel,
    [ATTRIBUTE_MANA]      = manaAttributeLabel,
    [ATTRIBUTE_AGILITY]   = agilityAttributeLabel,
    [ATTRIBUTE_DODGE]     = dodgeAttributeLabel,
    [ATTRIBUTE_WALKING]   = walkingAttributeLabel,
    [ATTRIBUTE_LUCK]      = luckAttributeLabel,
  }

  attributeActLabel =
  {
    [ATTRIBUTE_ATTACK]    = attackAttributeActLabel,
    [ATTRIBUTE_DEFENSE]   = defenseAttributeActLabel,
    [ATTRIBUTE_WILLPOWER] = willPowerAttributeActLabel,
    [ATTRIBUTE_HEALTH]    = healthAttributeActLabel,
    [ATTRIBUTE_MANA]      = manaAttributeActLabel,
    [ATTRIBUTE_AGILITY]   = agilityAttributeActLabel,
    [ATTRIBUTE_DODGE]     = dodgeAttributeActLabel,
    [ATTRIBUTE_WALKING]   = walkingAttributeActLabel,
    [ATTRIBUTE_LUCK]      = luckAttributeActLabel,
  }

  attackAttributeAddButton.attributeId    = ATTRIBUTE_ATTACK
  defenseAttributeAddButton.attributeId   = ATTRIBUTE_DEFENSE
  willPowerAttributeAddButton.attributeId = ATTRIBUTE_WILLPOWER
  healthAttributeAddButton.attributeId    = ATTRIBUTE_HEALTH
  manaAttributeAddButton.attributeId      = ATTRIBUTE_MANA
  agilityAttributeAddButton.attributeId   = ATTRIBUTE_AGILITY
  dodgeAttributeAddButton.attributeId     = ATTRIBUTE_DODGE
  walkingAttributeAddButton.attributeId   = ATTRIBUTE_WALKING
  luckAttributeAddButton.attributeId      = ATTRIBUTE_LUCK

  attackAttributeAddButton.onClick    = GameAttributes.onClickAddButton
  defenseAttributeAddButton.onClick   = GameAttributes.onClickAddButton
  willPowerAttributeAddButton.onClick = GameAttributes.onClickAddButton
  healthAttributeAddButton.onClick    = GameAttributes.onClickAddButton
  manaAttributeAddButton.onClick      = GameAttributes.onClickAddButton
  agilityAttributeAddButton.onClick   = GameAttributes.onClickAddButton
  dodgeAttributeAddButton.onClick     = GameAttributes.onClickAddButton
  walkingAttributeAddButton.onClick   = GameAttributes.onClickAddButton
  luckAttributeAddButton.onClick      = GameAttributes.onClickAddButton

  connect(g_game, {
    onGameStart        = GameAttributes.online,
    onPlayerAttributes = GameAttributes.onPlayerAttributes
  })

  GameInterface.setupMiniWindow(attributeWindow, attributeTopMenuButton)

  if g_game.isOnline() then
    GameAttributes.online()
  end
end

function GameAttributes.terminate()
  disconnect(g_game, {
    onGameStart        = GameAttributes.online,
    onPlayerAttributes = GameAttributes.onPlayerAttributes
  })

  attributeTopMenuButton:destroy()
  attributeWindow:destroy()

  attributeTopMenuButton = nil
  attributeWindow = nil
  attributeFooter = nil

  attackAttributeAddButton    = nil
  defenseAttributeAddButton   = nil
  willPowerAttributeAddButton = nil
  healthAttributeAddButton    = nil
  manaAttributeAddButton      = nil
  agilityAttributeAddButton   = nil
  dodgeAttributeAddButton     = nil
  walkingAttributeAddButton   = nil
  luckAttributeAddButton      = nil

  attackAttributeLabel    = nil
  defenseAttributeLabel   = nil
  willPowerAttributeLabel = nil
  healthAttributeLabel    = nil
  manaAttributeLabel      = nil
  agilityAttributeLabel   = nil
  dodgeAttributeLabel     = nil
  walkingAttributeLabel   = nil
  luckAttributeLabel      = nil

  attackAttributeActLabel    = nil
  defenseAttributeActLabel   = nil
  willPowerAttributeActLabel = nil
  healthAttributeActLabel    = nil
  manaAttributeActLabel      = nil
  agilityAttributeActLabel   = nil
  dodgeAttributeActLabel     = nil
  walkingAttributeActLabel   = nil
  luckAttributeActLabel      = nil

  availablePointsLabel = nil
  pointsCostLabel      = nil

  g_keyboard.unbindKeyDown('Ctrl+Shift+U')

  _G.GameAttributes = nil
end

function GameAttributes.toggle()
  GameInterface.toggleMiniWindow(attributeWindow)
end

function GameAttributes.online()
  GameInterface.setupMiniWindow(attributeWindow, attributeTopMenuButton)

  GameAttributes.clearWindow()

  g_game.sendAttributeBuffer(string.format("%d", attribute_flag_updateList))
end

function GameAttributes.clearWindow()
  attackAttributeActLabel:setText(string.format('%.2f', 0))
  defenseAttributeActLabel:setText(string.format('%.2f', 0))
  willPowerAttributeActLabel:setText(string.format('%.2f', 0))
  healthAttributeActLabel:setText(string.format('%.2f', 0))
  manaAttributeActLabel:setText(string.format('%.2f', 0))
  agilityAttributeActLabel:setText(string.format('%.2f', 0))
  dodgeAttributeActLabel:setText(string.format('%.2f', 0))
  walkingAttributeActLabel:setText(string.format('%.2f', 0))
  luckAttributeActLabel:setText(string.format('%.2f', 0))

  availablePointsLabel:setText(string.format('Pts to use: %d', 0))
  pointsCostLabel:setText(string.format('Cost: %d', 0))

  attackAttributeActLabel:setTooltip('')
  defenseAttributeActLabel:setTooltip('')
  willPowerAttributeActLabel:setTooltip('')
  healthAttributeActLabel:setTooltip('')
  manaAttributeActLabel:setTooltip('')
  agilityAttributeActLabel:setTooltip('')
  dodgeAttributeActLabel:setTooltip('')
  walkingAttributeActLabel:setTooltip('')
  luckAttributeActLabel:setTooltip('')

  availablePointsLabel:setTooltip(string.format('Used points with cost: %d\nUsed points without cost: %d', 0, 0))
  pointsCostLabel:setTooltip(string.format('Points to increase cost: %d', 0))

  attackAttributeActLabel:setColor('white')
  defenseAttributeActLabel:setColor('white')
  willPowerAttributeActLabel:setColor('white')
  healthAttributeActLabel:setColor('white')
  manaAttributeActLabel:setColor('white')
  agilityAttributeActLabel:setColor('white')
  dodgeAttributeActLabel:setColor('white')
  walkingAttributeActLabel:setColor('white')
  luckAttributeActLabel:setColor('white')
end

function GameAttributes.onPlayerAttributes(tooltips, attributes, availablePoints, usedPoints, distributionPoints, pointsCost, pointsToCostIncrease)
  if not attributeLabel or not attributeActLabel then
    return
  end

  for _, attribute in ipairs(attributes) do
    local id                 = attribute[1]
    local distributionPoints = attribute[2]
    local alignmentPoints    = attribute[3]
    local alignmentMaxPoints = attribute[4]
    local buffPoints         = attribute[5]
    local total              = attribute[6]

    if attributeActLabel[id] then
      local distributionPointsText = distributionPoints ~= 0 and string.format('Distribution: %d\n', distributionPoints)                         or ''
      local alignmentPointsText    = alignmentPoints    ~= 0 and string.format('Alignment: %.2f of %.2f\n', alignmentPoints, alignmentMaxPoints) or ''
      local buffPointsText         = buffPoints         ~= 0 and string.format('Buff/Debuff: %s%.2f\n', buffPoints > 0 and '+' or '', buffPoints)   or ''

      local moreThanMaximum = (distributionPoints + alignmentPoints + buffPoints) > total
      local totalPointsText = total ~= 0 and string.format('Total: %.2f%s', total, moreThanMaximum and '\n(exceed the maximum value)' or '') or ''

      attributeActLabel[id]:setText(string.format('%0.02f', total))
      attributeActLabel[id]:setTooltip(string.format('%s%s%s%s', distributionPointsText, alignmentPointsText, buffPointsText, totalPointsText))
      attributeActLabel[id]:setColor(buffPoints > 0 and 'green' or buffPoints < 0 and 'red' or 'white')
    end

    if attributeLabel[id] then
      if table.size(tooltips) > 1 then
        attributeLabel[id]:setTooltip(tooltips[id])
      end
    end
  end

  _availablePoints = availablePoints
  availablePointsLabel:setText(string.format('Pts to use: %d', availablePoints))
  availablePointsLabel:setTooltip(string.format('Used points with cost: %d\nUsed points without cost: %d', usedPoints, distributionPoints))
  pointsCostLabel:setText(string.format('Cost: %d', pointsCost))
  pointsCostLabel:setTooltip(string.format('Points to increase cost: %d', pointsToCostIncrease))
end

function GameAttributes.sendAdd(attributeId)
  g_game.sendAttributeBuffer(string.format("%d", attributeId))
end

function GameAttributes.onClickAddButton(widget)
  if not widget.attributeId then
    return
  end

  GameAttributes.sendAdd(widget.attributeId)
end
