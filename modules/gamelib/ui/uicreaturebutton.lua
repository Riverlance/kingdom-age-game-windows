-- @docclass
UICreatureButton = extends(UIWidget, "UICreatureButton")

local alpha = 'AA' -- Alpha

local CreatureButtonColors =
{
  onIdle = { notHovered = '#888888'..alpha, hovered = '#FFFFFF'..alpha },

  onTargetedOffensive = { notHovered = '#FF0000'..alpha, hovered = '#FF8888'..alpha },
  onTargetedBalanced  = { notHovered = '#FFFF00'..alpha, hovered = '#FFFF88'..alpha },
  onTargetedDefensive = { notHovered = '#00FFFF'..alpha, hovered = '#88FFFF'..alpha },

  onFollowed = { notHovered = '#00FF00'..alpha, hovered = '#88FF88'..alpha }
}

function UICreatureButton.create()
  local button = UICreatureButton.internalCreate()
  button:setFocusable(false)

  button.creature = nil

  -- Used when creature is nil
  button.cid      = nil
  button.outfit   = nil
  button.name     = nil
  button.nickname = ''

  button.healthPercent  = 100
  button.manaPercent    = 100
  button.position       = { x = 0, y = 0, z = 0 }
  button.ping           = 0
  button.creatureTypeId = CreatureTypePlayer
  button.shieldId       = ShieldNone
  button.skullId        = SkullNone
  button.emblemId       = EmblemNone
  button.specialIconId  = SpecialIconNone
  button.vocationId     = VocationLearner -- Player only

  button.masterCid      = 0 -- Summon only (updated manually)

  button.isHovered  = false
  button.isTarget   = false
  button.isFollowed = false

  -- Creation time
  button.lastAppear = os.time()

  return button
end

function UICreatureButton:setCreature(data)
  if type(data) == "userdata" then
    local position = data:getPosition()

    self.creature = data

    -- Last known data

    self.cid      = data:getId()
    self.outfit   = data:getOutfit()
    self.name     = data:getName()
    self.nickname = data:getNickname()

    self.healthPercent  = data:getHealthPercent()
    self.manaPercent    = data:getManaPercent()
    self.position.x     = position.x
    self.position.y     = position.y
    self.position.z     = position.z
    self.ping           = 0
    self.creatureTypeId = data:getType()
    self.shieldId       = data:getShield()
    self.skullId        = data:getSkull()
    self.emblemId       = data:getEmblem()
    self.specialIconId  = data:getSpecialIcon()
    self.vocationId     = data:getVocation()

    return
  end

  if not data.cid or not data.outfit or not data.name then
    print_traceback('UICreatureButton:setCreature - attempt to set a creature without needed data')
    return
  end

  -- Copy data to button
  for k, v in pairs(data) do
    self[k] = v
  end
end



function UICreatureButton:setup(data)
  -- Set creature data
  self:setCreature(data)

  -- Id
  local creatureName = self:getCreatureName(true)
  if creatureName == '' then
    -- If you want without name, change the nickname after setup
    -- Name is needed for the UICreatureButton id
    print_traceback('UICreatureButton:setup - attempt to setup a creature without a name')
    return
  end
  self:setId('CreatureButton_' .. creatureName:gsub('%s','_'))

  -- Update data
  self:update()
end

function UICreatureButton:update()
  self:updateCreature(true)
  self:updateStaticSquare()
  self:updateLabelText('')
  self:updateHealthPercent(true)
  self:updateManaPercent(true)
  self:updatePosition(true)
  self:updatePing(true)
  self:updateCreatureType()
  self:updateShield(true)
  self:updateSkull(true)
  self:updateEmblem(true)
  self:updateSpecialIcon(true)
  self:updateVocation(true)
end

function UICreatureButton:updateCreature(data)
  local creatureWidget = self:getChildById('creature')
  if not creatureWidget then
    return
  end

  if data ~= true then
    local _type = type(data)
    if _type == 'userdata' then
      self.creature = data
    elseif _type == 'table' then
      self.outfit = data
    else
      print_traceback('UICreatureButton:updateCreature - attempt to set creature as an unknown type of data')
      return
    end
  end

  -- Creature
  if self.creature then
    creatureWidget:setCreature(self.creature)

  -- Outfit
  elseif self.outfit then
    creatureWidget:setOutfit(self.outfit)
  end

  self:updateCreatureMinimapWidgetCreature()
end

function UICreatureButton:updateStaticSquare() -- Update border
  local creatureWidget = self:getChildById('creature')
  local labelWidget    = self:getChildById('label')

  if not creatureWidget and not labelWidget then
    return
  end

  local color = CreatureButtonColors.onIdle

  if self.isTarget then
    local fightMode = g_game.getFightMode()

    if fightMode == FightOffensive then
      color = CreatureButtonColors.onTargetedOffensive
    elseif fightMode == FightBalanced then
      color = CreatureButtonColors.onTargetedBalanced
    elseif fightMode == FightDefensive then
      color = CreatureButtonColors.onTargetedDefensive
    else
      color = CreatureButtonColors.onTargetedOffensive
    end

  elseif self.isFollowed then
    color = CreatureButtonColors.onFollowed
  end

  color = self.isHovered and color.hovered or color.notHovered

  -- Colored border
  if self.isHovered or self.isTarget or self.isFollowed then
    if creatureWidget then
      if self.creature then
        self.creature:showStaticSquare(color)
      end
      creatureWidget:setBorderWidth(1)
      creatureWidget:setBorderColor(color)
    end

    if labelWidget then
      labelWidget:setColor(color)
    end

  -- No color/border
  else
    if creatureWidget then
      if self.creature then
        self.creature:hideStaticSquare()
      end
      creatureWidget:setBorderWidth(0)
    end

    if labelWidget then
      labelWidget:setColor(color)
    end
  end
end

function UICreatureButton:getCreatureMinimapWidget()
  if not modules.game_minimap then
    return nil -- Game Minimap module is not set
  end

  local minimapWidget = GameMinimap.getMinimapWidget()
  return minimapWidget.alternatives[self.cid]
end

function UICreatureButton:enableCreatureMinimapWidget()
  if not modules.game_minimap then
    return false -- Game Minimap module is not set
  end

  local creatureMinimapWidget = self:getCreatureMinimapWidget()
  if creatureMinimapWidget then
    return false -- Added already
  end

  local minimapWidget   = GameMinimap.getMinimapWidget()
  creatureMinimapWidget = g_ui.createWidget('CreatureButtonMinimapWidget')

  creatureMinimapWidget.alternativeId = self.cid
  self:updateCreatureMinimapWidgetCreature(creatureMinimapWidget)
  self:updateCreatureMinimapWidgetPosition(creatureMinimapWidget, true)
  self:updateCreatureMinimapWidgetLabelText(creatureMinimapWidget, true)
  self:updateCreatureMinimapWidgetTooltip(creatureMinimapWidget)

  connect(self, {
    onDestroy = function()
      local creatureMinimapWidget = self:getCreatureMinimapWidget()
      if creatureMinimapWidget then
        creatureMinimapWidget:destroy()
      end
    end
  })

  minimapWidget:addAlternativeWidget(creatureMinimapWidget)

  return true -- Added successfully
end

function UICreatureButton:disableCreatureMinimapWidget()
  if not modules.game_minimap then
    return false -- Game Minimap module is not set
  end

  local creatureMinimapWidget = self:getCreatureMinimapWidget()
  if not creatureMinimapWidget then
    return false -- Not found
  end

  creatureMinimapWidget:destroy()

  return true -- Removed successfully
end

function UICreatureButton:updateCreatureMinimapWidgetCreature(creatureMinimapWidget)
  if not modules.game_minimap then
    return false -- Game Minimap module is not set
  end

  local creatureMinimapWidget = creatureMinimapWidget or self:getCreatureMinimapWidget()
  if not creatureMinimapWidget then
    return false -- Not found
  end

  local minimapWidgetCreature = creatureMinimapWidget:getChildById('creature')
  if not minimapWidgetCreature then
    return false
  end

  local ret = false

  -- Creature
  if self.creature then
    minimapWidgetCreature:setCreature(self.creature)
    ret = true -- Updated successfully

  -- Outfit
  elseif self.outfit then
    minimapWidgetCreature:setOutfit(self.outfit)
    ret = true -- Updated successfully
  end

  return ret
end

function UICreatureButton:updateCreatureMinimapWidgetPosition(creatureMinimapWidget, ignoreTooltipUpdate)
  if not modules.game_minimap then
    return false -- Game Minimap module is not set
  end

  local creatureMinimapWidget = creatureMinimapWidget or self:getCreatureMinimapWidget()
  if not creatureMinimapWidget then
    return false -- Not found
  end

  local minimapWidget = GameMinimap.getMinimapWidget()

  creatureMinimapWidget.pos = self.position -- Position reference
  minimapWidget:centerInPosition(creatureMinimapWidget, self.position)

  if not ignoreTooltipUpdate then
    self:updateCreatureMinimapWidgetTooltip(creatureMinimapWidget)
  end

  return true -- Updated successfully
end

function UICreatureButton:updateCreatureMinimapWidgetLabelText(creatureMinimapWidget, ignoreTooltipUpdate)
  if not modules.game_minimap then
    return false -- Game Minimap module is not set
  end

  local creatureMinimapWidget = creatureMinimapWidget or self:getCreatureMinimapWidget()
  if not creatureMinimapWidget then
    return false -- Not found
  end

  local minimapWidgetTitleLabel = creatureMinimapWidget:getChildById('titleLabel')
  local labelWidget             = self:getChildById('label')
  if not minimapWidgetTitleLabel or not labelWidget then
    return false
  end

  minimapWidgetTitleLabel:setText(labelWidget:getText())

  if not ignoreTooltipUpdate then
    self:updateCreatureMinimapWidgetTooltip(creatureMinimapWidget)
  end

  return true -- Updated successfully
end

function UICreatureButton:updateCreatureMinimapWidgetTooltip(creatureMinimapWidget)
  if not modules.game_minimap then
    return false -- Game Minimap module is not set
  end

  local creatureMinimapWidget = creatureMinimapWidget or self:getCreatureMinimapWidget()
  if not creatureMinimapWidget then
    return false -- Not found
  end

  local minimapWidgetCreature   = creatureMinimapWidget:getChildById('creature')
  local minimapWidgetTitleLabel = creatureMinimapWidget:getChildById('titleLabel')
  if not minimapWidgetCreature or not minimapWidgetTitleLabel then
    return false
  end

  local minimapWidgetTooltip = string.format('%s\n%d, %d, %d', minimapWidgetTitleLabel:getText(), creatureMinimapWidget.pos.x, creatureMinimapWidget.pos.y, creatureMinimapWidget.pos.z)
  minimapWidgetCreature:setTooltip(minimapWidgetTooltip)
  minimapWidgetCreature:setPhantom(false)

  return true -- Updated successfully
end

function UICreatureButton:updateLabelText(nickname)
  local labelWidget = self:getChildById('label')
  if not labelWidget then
    return
  end

  self.nickname = nickname

  labelWidget:setText(self:getCreatureName())
  self:updateCreatureMinimapWidgetLabelText()
end

function UICreatureButton:updateHealthPercent(healthPercent)
  local healthBarWidget = self:getChildById('healthBar')
  if not healthBarWidget then
    return
  end

  if healthPercent ~= true then
    self.healthPercent = healthPercent
  end

  healthPercent = self.creature and self.creature:getHealthPercent() or self.healthPercent

  healthBarWidget:setPercent(healthPercent)
end

function UICreatureButton:updateManaPercent(manaPercent)
  local manaBarWidget = self:getChildById('manaBar')
  if not manaBarWidget then
    return
  end

  if manaPercent ~= true then
    self.manaPercent = manaPercent
  end

  manaPercent = self.creature and self.creature:getManaPercent() or self.manaPercent

  manaBarWidget:setPercent(manaPercent)
end

function UICreatureButton:updatePosition(position)
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  local positionLabelWidget = self:getChildById('positionLabel')
  if not positionLabelWidget then
    return
  end

  if position ~= true then
    self.position.x = position.x
    self.position.y = position.y
    self.position.z = position.z
  end

  if self.creature then
    local _position = self.creature:getPosition()
    position.x      = _position.x
    position.y      = _position.y
    position.z      = _position.z
  else
    position = self.position
  end

  local color

  if self.cid == localPlayer:getId() then
    color = 'darkGreen'
  else
    local localPlayerPos = localPlayer:getPosition()
    local distance       = getDistanceTo(localPlayerPos, position, true)

    -- Outer party shared experience distance limit
    if distance > 30 then
      color = 'red'

    -- Cannot see each other
    elseif not Position.isInRange(localPlayerPos, position, ScreenRangeX, ScreenRangeY) then
      color = 'yellow'

    -- Local player can see position
    else
      color = 'darkGreen'
    end
  end

  positionLabelWidget:setText(string.format('%d, %d, %d', position.x, position.y, position.z))
  positionLabelWidget:setColor(color)

  self:updateInfoIcon()
  self:updateCreatureMinimapWidgetPosition()
end

function UICreatureButton:updatePing(ping) -- See ClientTopMenu.updatePing
  local pingWidget = self:getChildById('pingLabel')
  if not pingWidget then
    return
  end

  if ping ~= true then
    self.ping = ping
  end

  ping = self.ping

  local text
  local color

  -- Unknown
  if ping < 0 then
    text  = '?'
    color = 'yellow'

  -- Known
  else
    text = string.format('%d ms', ping)

    if ping >= 500 then
      color = 'red'

    elseif ping >= 250 then
      color = 'yellow'

    else
      color = 'darkGreen'
    end
  end

  pingWidget:setText(text)
  pingWidget:setColor(color)
end

function UICreatureButton:updateCreatureType(creatureTypeId)
  local creatureTypeWidget = self:getChildById('creatureType')
  if not creatureTypeWidget then
    return
  end

  if creatureTypeId then
    self.creatureTypeId = creatureTypeId
  end

  creatureTypeId = self.creature and self.creature:getType() or self.creatureTypeId

  local path = getCreatureTypeImagePath(creatureTypeId)
  creatureTypeWidget:setImageSource(path)
  creatureTypeWidget:setOn(path ~= '')
end

function UICreatureButton:updateShield(shieldId)
  local shieldWidget = self:getChildById('shield')
  if not shieldWidget then
    return
  end

  if shieldId ~= true then
    self.shieldId = shieldId
  end

  shieldId = self.creature and self.creature:getShield() or self.shieldId

  local path, blink = getShieldImagePathAndBlink(shieldId)
  shieldWidget:setImageSource(path)
  shieldWidget:setOn(path ~= '')

  self:updateInfoIcon()
end

function UICreatureButton:updateSkull(skullId)
  local skullWidget = self:getChildById('skull')
  if not skullWidget then
    return
  end

  if skullId ~= true then
    self.skullId = skullId
  end

  skullId = self.creature and self.creature:getSkull() or self.skullId

  local path = getSkullImagePath(skullId)
  skullWidget:setImageSource(path)
  skullWidget:setOn(path ~= '')
end

function UICreatureButton:updateEmblem(emblemId)
  local emblemWidget = self:getChildById('emblem')
  if not emblemWidget then
    return
  end

  if emblemId ~= true then
    self.emblemId = emblemId
  end

  emblemId = self.creature and self.creature:getEmblem() or self.emblemId

  local path = getEmblemImagePath(emblemId)
  emblemWidget:setImageSource(path)
  emblemWidget:setOn(path ~= '')
end

function UICreatureButton:updateSpecialIcon(specialIconId)
  local specialIconWidget = self:getChildById('specialIcon')
  if not specialIconWidget then
    return
  end

  if specialIconId ~= true then
    self.specialIconId = specialIconId
  end

  specialIconId = self.creature and self.creature:getSpecialIcon() or self.specialIconId

  local path = getSpecialIconPath(specialIconId)
  specialIconWidget:setImageSource(path)
  specialIconWidget:setOn(path ~= '')
end

function UICreatureButton:updateVocation(vocationId)
  if vocationId ~= true then
    self.vocationId = vocationId
  end

  -- vocationId = self.creature and self.creature:getVocation() or self.vocationId
end

function UICreatureButton:updateInfoIcon()
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  local infoIconWidget = self:getChildById('infoIcon')
  if not infoIconWidget then
    return
  end

  local distance = getDistanceTo(localPlayer:getPosition(), self.position, true)

  local hierarchyStr = tr('Hierarchy: %s', self.creatureTypeId == CreatureTypePlayer and ShieldStr[self.shieldId] or table.contains({ CreatureTypeSummonOwn, CreatureTypeSummonOther }, self.creatureTypeId) and tr('Summon') or tr('Unknown'))
  local distanceStr  = tr('Distance: %d SQM%s', distance, distance > 1 and 's' or '')

  infoIconWidget:setTooltip(string.format('%s\n%s', hierarchyStr, distanceStr))
end





function UICreatureButton:getCreatureName(ignoreNickname)
  local nickname = self.creature and self.creature:getNickname() or self.nickname

  return not ignoreNickname and nickname ~= '' and nickname or self.creature and self.creature:getName() or self.name or ''
end
