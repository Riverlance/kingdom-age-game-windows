_G.GameHotkeys = { }

dofiles('ui')

HOTKEY_MANAGER_USE     = nil
HOTKEY_MANAGER_USEWITH = 1

HotkeyColors =
{
  text = '#333B43',
  textAutoSend = '#FFFFFF',
  itemUse = '#AEF2FF',
  itemUseWith = '#F8E127',
}

HotkeyStatus =
{
  Applied = {color = 'alpha',     focusColor = '#CCCCCC22'},
  Added   = {color = '#00FF0022', focusColor = '#00CC0022'},
  Edited  = {color = '#FFFF0022', focusColor = '#CCCC0022'},
  Deleted = {color = '#FF000022', focusColor = '#CC000022'},
}

hotkeysManagerLoaded = false
hotkeysWindow = nil
hotkeysButton = nil
currentHotkeyLabel = nil
hotkeyItemLabel = nil
currentItemPreview = nil
itemWidget = nil
applyHotkeyLabel = nil
resetHotketLabel = nil
addHotkeyButton = nil
removeHotkeyButton = nil
hotkeyTextLabel = nil
hotkeyText = nil
sendAutomatically = nil
defaultComboKeys = nil
currentHotkeys = nil
boundCombosCallback = {}
hotkeyList = {}
lastHotkeyTime = g_clock.millis()



function GameHotkeys.init()
  -- Alias
  GameHotkeys.m = modules.game_hotkeys

  g_ui.importStyle('hotkeylabel.otui')

  hotkeysButton = ClientTopMenu.addLeftGameButton('hotkeysButton', tr('Hotkeys') .. ' (Ctrl+K)', '/images/ui/top_menu/hotkeys', GameHotkeys.toggle)
  hotkeysWindow = g_ui.displayUI('hotkeys')
  hotkeysWindow:setVisible(false)
  g_keyboard.bindKeyDown('Ctrl+K', GameHotkeys.toggle)

  currentHotkeys = hotkeysWindow:getChildById('currentHotkeys')
  currentHotkeys.onChildFocusChange = function(self, hotkeyLabel, unfocused) GameHotkeys.onSelectHotkeyLabel(hotkeyLabel, unfocused) end
  g_keyboard.bindKeyPress('Down', function() currentHotkeys:focusNextChild(KeyboardFocusReason) end, hotkeysWindow)
  g_keyboard.bindKeyPress('Up', function() currentHotkeys:focusPreviousChild(KeyboardFocusReason) end, hotkeysWindow)

  applyHotkeyButton = hotkeysWindow:getChildById('applyHotkeyButton')
  resetHotkeyButton = hotkeysWindow:getChildById('resetHotkeyButton')
  addHotkeyButton = hotkeysWindow:getChildById('addHotkeyButton')
  removeHotkeyButton = hotkeysWindow:getChildById('removeHotkeyButton')

  hotkeyItemLabel = hotkeysWindow:getChildById('hotkeyItemLabel')
  currentItemPreview = hotkeysWindow:getChildById('itemPreview')
  currentItemPreview.onDragEnter = GameHotkeys.dragEnterItemPreview
  currentItemPreview.onDragLeave = GameHotkeys.dragLeaveItemPreview
  currentItemPreview.onDrop = GameHotkeys.dropOnItemPreview

  hotkeyTextLabel = hotkeysWindow:getChildById('hotkeyTextLabel')
  hotkeyText = hotkeysWindow:getChildById('hotkeyText')
  sendAutomatically = hotkeysWindow:getChildById('sendAutomatically')

  if g_game.isOnline() then
    GameHotkeys.online()
  end

  connect(g_game, {
    onGameStart = GameHotkeys.online,
    onGameEnd   = GameHotkeys.offline
  })
end

function GameHotkeys.terminate()
  disconnect(g_game, {
    onGameStart = GameHotkeys.online,
    onGameEnd   = GameHotkeys.offline
  })

  g_keyboard.unbindKeyDown('Ctrl+K')

  hotkeysWindow:destroy()
  hotkeysButton:destroy()

  _G.GameHotkeys = nil
end

function GameHotkeys.online()
  GameHotkeys.reload()
  GameHotkeys.hide()
end

function GameHotkeys.offline()
  GameHotkeys.unload()
  GameHotkeys.hide()
end

function GameHotkeys.isOpen()
  return hotkeysWindow:isVisible()
end

function GameHotkeys.show()
  if not g_game.isOnline() then
    return
  end
  if modules.ka_game_hotkeybars then
    GameHotkeybars.updateDraggable(true)
  end
  hotkeysWindow:show()
  hotkeysWindow:raise()
  hotkeysWindow:focus()
  hotkeysButton:setOn(true)
end

function GameHotkeys.hide()
  hotkeysWindow:hide()
  if modules.ka_game_hotkeybars then
    GameHotkeybars.updateDraggable(false)
  end
  hotkeysButton:setOn(false)
end

function GameHotkeys.toggle()
  if not hotkeysWindow:isVisible() then
    GameHotkeys.show()
  else
    GameHotkeys.hide()
  end
end

function GameHotkeys.setStatus(hotkeyLabel, status)
  hotkeyLabel.status = status
  GameHotkeys.updateHotkeyLabel(hotkeyLabel)
  GameHotkeys.updateHotkeyForm()
end

function GameHotkeys.apply(hotkey, save)
  if not hotkey then
    if currentHotkeyLabel then
      hotkey = currentHotkeyLabel
    else
      return
    end
  end
  if hotkey.status == HotkeyStatus.Deleted then
    hotkey:destroy()
    hotkey = nil
  else
    hotkeyList[hotkey.keyCombo] = {
      keyCombo = hotkey.keyCombo,
      autoSend = hotkey.autoSend,
      itemId   = hotkey.itemId,
      subType  = hotkey.subType,
      useType  = hotkey.useType,
      value    = hotkey.value
    }
    GameHotkeys.setStatus(hotkey, HotkeyStatus.Applied)
  end

  save = save and true
  if save then
    GameHotkeys.save()
  end

  if modules.ka_game_hotkeybars then
    GameHotkeybars.onUpdateHotkeys()
  end
end

function GameHotkeys.applyChanges()
  for index, hotkey in ipairs(currentHotkeys:getChildren()) do
    if hotkey.status ~= HotkeyStatus.Applied then
      GameHotkeys.apply(hotkey, false)
    end
  end
end

function GameHotkeys.resetHotkey(hotkey)
  if not hotkey then
    if currentHotkeyLabel then
      hotkey = currentHotkeyLabel
    else
      return
    end
  end
  if hotkey.status == HotkeyStatus.Added then
      hotkey:destroy()
      hotkey = nil
  elseif hotkey.status ~= HotkeyStatus.Applied then
    local key = hotkeyList[hotkey.keyCombo]
    hotkey.autoSend = key.autoSend
    hotkey.itemId   = key.itemId
    hotkey.subType  = key.subType
    hotkey.useType  = key.useType
    hotkey.value    = key.value
    GameHotkeys.setStatus(hotkey, HotkeyStatus.Applied)
  end
end

function GameHotkeys.discardChanges()
  for index, hotkey in ipairs(currentHotkeys:getChildren()) do
    GameHotkeys.resetHotkey(hotkey)
  end
end

function GameHotkeys.sort()
  local hotkeys = currentHotkeys:getChildren()
  table.sort(hotkeys, function(a,b)
    if a:getId():len() < b:getId():len() then
      return true
    elseif a:getId():len() == b:getId():len() then
      return a:getId() < b:getId()
    else
      return false
    end
  end)
  for newIndex, hotkey in ipairs(hotkeys) do
    currentHotkeys:moveChildToIndex(hotkey, newIndex)
  end
end

function GameHotkeys.ok()
  GameHotkeys.applyChanges()
  GameHotkeys.save()
  if modules.ka_game_hotkeybars then
    GameHotkeybars.onUpdateHotkeys()
  end
  GameHotkeys.hide()
end

function GameHotkeys.cancel()
  GameHotkeys.discardChanges()
  GameHotkeys.hide()
end

function GameHotkeys.load(forceDefaults)
  hotkeysManagerLoaded = false
  local hotkeySettings = Client.getPlayerSettings():getNode('hotkeys') or {}
  if table.empty(hotkeySettings) then
    GameHotkeys.loadDefaultComboKeys()
  end
  for index, keySettings in pairs(hotkeySettings) do
    if tonumber(index) then
      GameHotkeys.addKeyCombo(keySettings.keyCombo, keySettings)
    else --retrocompatibility
      keySettings.keyCombo = index
      GameHotkeys.addKeyCombo(index, keySettings)
    end
  end
  GameHotkeys.sort()
  hotkeysManagerLoaded = true
end

function GameHotkeys.unload()
  GamePowerHotkeys.unload()

  for keyCombo,callback in pairs(boundCombosCallback) do
    g_keyboard.unbindKeyPress(keyCombo, callback)
  end

  boundCombosCallback = {}
  currentHotkeys:destroyChildren()
  currentHotkeyLabel = nil
  GameHotkeys.updateHotkeyForm(true)
  hotkeyList = {}
end

function GameHotkeys.reset()
  GameHotkeys.unload()
  GameHotkeys.load(true)
end

function GameHotkeys.reload()
  GameHotkeys.unload()
  GameHotkeys.load()
end

function GameHotkeys.save()
  local settings = Client.getPlayerSettings()
  local hotkeys = {}

  GameHotkeys.sort()
  for index, hotkey in ipairs(currentHotkeys:getChildren()) do
    local powerId  = GamePowerHotkeys.getIdByString(hotkey.value)
    hotkey.autoSend = powerId and true or hotkey.autoSend

    hotkeys[index] = {
      keyCombo = hotkey.keyCombo,
      autoSend = hotkey.autoSend or nil,
      itemId = hotkey.itemId or nil,
      subType = hotkey.subType or nil,
      useType = hotkey.useType or nil,
      value = string.exists(hotkey.value) and hotkey.value or nil
    }
  end
  settings:setNode('hotkeys', hotkeys)
  settings:save()
end

function GameHotkeys.loadDefaultComboKeys()
  if not defaultComboKeys then
    for i=1,12 do
      GameHotkeys.addKeyCombo('F' .. i)
    end
    for i=1,12 do
      GameHotkeys.addKeyCombo('Shift+F' .. i)
    end
    for i=1,12 do
      GameHotkeys.addKeyCombo('Ctrl+F' .. i)
    end
  else
    for keyCombo, keySettings in pairs(defaultComboKeys) do
      GameHotkeys.addKeyCombo(keyCombo, keySettings)
    end
  end
end

function GameHotkeys.setDefaultComboKeys(combo)
  defaultComboKeys = combo
end

function GameHotkeys.clearObject()
  currentHotkeyLabel.itemId = nil
  currentHotkeyLabel.subType = nil
  currentHotkeyLabel.useType = nil
  currentHotkeyLabel.autoSend = nil
  currentHotkeyLabel.value = nil
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm(true)
  if modules.ka_game_hotkeybars then
    GameHotkeybars.onUpdateHotkeys()
  end
end

function GameHotkeys.addHotkey(keySettings)
  local assignWindow = g_ui.createWidget('HotkeyAssignWindow', rootWidget)
  assignWindow:grabKeyboard()

  local comboLabel = assignWindow:getChildById('comboPreview')
  comboLabel.keyCombo = ''
  assignWindow.onKeyDown = GameHotkeys.hotkeyCapture

  local addButtonWidget = assignWindow:getChildById('addButton')
  addButtonWidget.onClick = function(widget)
    local keyCombo = assignWindow:getChildById('comboPreview').keyCombo
    GameHotkeys.addKeyCombo(keyCombo, keySettings, true)
    assignWindow:destroy()
  end

  local cancelButton = assignWindow:getChildById('cancelButton')
  cancelButton.onClick = function (widget)
    assignWindow:destroy()
  end
end

function GameHotkeys.addKeyCombo(keyCombo, keySettings, focus)
  if not string.exists(keyCombo) then
    return
  end
  hotkeyList[keyCombo] = keySettings or {}

  local hotkeyLabel = currentHotkeys:getChildById(keyCombo)
  currentHotkeyLabel = hotkeyLabel
  if not hotkeyLabel then
    hotkeyLabel = g_ui.createWidget('HotkeyListLabel')
    hotkeyLabel:setId(keyCombo)
    if hotkeysManagerLoaded then --adding new hotkey
      GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Added)
      currentHotkeys:insertChild(1, hotkeyLabel)
    else --loading hotkey
      GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Applied)
      currentHotkeys:addChild(hotkeyLabel)
    end
    GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  end
  hotkeyLabel.keyCombo = keyCombo
  if keySettings then
    if keySettings.item then
      hotkeyLabel.autoSend = true
      hotkeyLabel.itemId = keySettings.item:getId()
      if keySettings.item:isFluidContainer() then
          currentHotkeyLabel.subType = keySettings.item:getSubType()
      end
      if keySettings.item:isMultiUse() then
        currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
      else
        currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
      end
    else
      if keySettings.powerId then
        keySettings.value = '/power ' .. keySettings.powerId
        keySettings.autoSend = true
      end
      local powerId = GamePowerHotkeys.getIdByString(keySettings.value or '')
      keySettings.autoSend = powerId and true or keySettings.autoSend
      hotkeyLabel.autoSend = toboolean(keySettings.autoSend)
      hotkeyLabel.itemId = tonumber(keySettings.itemId)
      hotkeyLabel.subType = tonumber(keySettings.subType)
      hotkeyLabel.useType = tonumber(keySettings.useType)
      if keySettings.value then
        hotkeyLabel.value = tostring(keySettings.value)
      end
    end
    if keySettings.hotkeyBar then
      keySettings.hotkeyBar:addHotkey(keyCombo, keySettings.mousePos)
      GameHotkeys.apply(hotkeyLabel, true)
    end
  else
    hotkeyLabel.keyCombo = keyCombo
    hotkeyLabel.autoSend = false
    hotkeyLabel.itemId = nil
    hotkeyLabel.subType = nil
    hotkeyLabel.useType = nil
    hotkeyLabel.value = ""
  end
  boundCombosCallback[keyCombo] = function()
    local textEdit = GameConsole.getFooterPanel():getChildById('consoleTextEdit')
    if textEdit and textEdit:isEnabled() and string.match(keyCombo, "^%C$") then
      return
    end

    GameHotkeys.doKeyCombo(keyCombo)
  end

  g_keyboard.bindKeyPress(keyCombo, boundCombosCallback[keyCombo])
  GameHotkeys.onEdit(hotkeyLabel)
  GameHotkeys.updateHotkeyLabel(hotkeyLabel)
  if focus then
    currentHotkeys:focusChild(hotkeyLabel)
    currentHotkeys:ensureChildVisible(hotkeyLabel)
    GameHotkeys.updateHotkeyForm(true)
  end
end

function GameHotkeys.doKeyCombo(keyCombo, clickedWidget)
  if not g_game.isOnline() then
    return
  end

  local hotkey = hotkeyList[keyCombo]
  if not hotkey then
    return
  end

  local actualTime = g_clock.millis()
  if actualTime - lastHotkeyTime < ClientOptions.getOption('hotkeyDelay') then
    return
  end
  lastHotkeyTime = actualTime

  if hotkey.itemId == nil then
    if not hotkey.value or #hotkey.value == 0 then
      return
    end

    if hotkey.autoSend then
    local powerId  = GamePowerHotkeys.getIdByString(hotkey.value)
      if powerId then
        GamePowerHotkeys.doKeyCombo(keyCombo, clickedWidget, { hotkey = hotkey, actualTime = actualTime })
        return
      end
      GameConsole.sendMessage(hotkey.value)
    else
      GameConsole.setTextEditText(hotkey.value)
    end
  elseif hotkey.useType == HOTKEY_MANAGER_USE then
    if g_game.getClientVersion() < 780 or hotkey.subType then
      local item = g_game.findPlayerItem(hotkey.itemId, hotkey.subType or -1)
      if item then
        g_game.use(item)
      end
    else
      g_game.useInventoryItem(hotkey.itemId)
    end
  elseif hotkey.useType == HOTKEY_MANAGER_USEWITH then
    local item = Item.create(hotkey.itemId)
    if g_game.getClientVersion() < 780 or hotkey.subType then
      local tmpItem = g_game.findPlayerItem(hotkey.itemId, hotkey.subType or -1)
      if not tmpItem then
        return
      end

      item = tmpItem
    end
    GameInterface.startUseWith(item)
  end
end

function GameHotkeys.getHotkey(keyCombo)
  if not g_game.isOnline() then
    return nil
  end

  local hotkey = hotkeyList[keyCombo]
  if not hotkey then
    return nil
  end

  if hotkey.itemId == nil then
    if not hotkey.value or #hotkey.value == 0 then
      return nil
    end

    local powerHotkey = GamePowerHotkeys.getHotkey(keyCombo, { hotkey = hotkey })
    if powerHotkey then
      return powerHotkey
    end
    return { type = 'text', autoSend = hotkey.autoSend, value = hotkey.value }

  else
    return { type = 'item', id = hotkey.itemId, useType = hotkey.useType }
  end
end

function GameHotkeys.updateHotkeyLabel(hotkeyLabel)
  if not hotkeyLabel then
    return
  end
  hotkeyLabel:setBackgroundColor(hotkeyLabel:isFocused() and hotkeyLabel.status.focusColor or hotkeyLabel.status.color)
  local text = string.format('%s: ', hotkeyLabel.keyCombo)

  if hotkeyLabel.useType == HOTKEY_MANAGER_USEWITH then
    hotkeyLabel:setText(tr('%s: [Item] Use object with crosshair.', hotkeyLabel.keyCombo))
    hotkeyLabel:setColor(HotkeyColors.itemUseWith)

  elseif hotkeyLabel.itemId ~= nil then
    hotkeyLabel:setText(tr('%s: [Item] Use object.', hotkeyLabel.keyCombo))
    hotkeyLabel:setColor(HotkeyColors.itemUse)

  elseif not GamePowerHotkeys.updateHotkeyLabel(hotkeyLabel, { text = text }) then
    if hotkeyLabel.value then
      if hotkeyLabel.value ~= '' then
        text = text .. '[Text] ' .. hotkeyLabel.value
      end
    end

    hotkeyLabel:setText(text)

    if hotkeyLabel.autoSend then
      hotkeyLabel:setColor(HotkeyColors.autoSend)
    else
      hotkeyLabel:setColor(HotkeyColors.text)
    end
  end
end

function GameHotkeys.updateHotkeyList()
  local hotkeys = currentHotkeys:getChildren()
  for _, hotkey in ipairs(hotkeys) do
    GameHotkeys.updateHotkeyLabel(hotkey)
  end
end

function GameHotkeys.updateHotkeyForm(reset)
  if currentHotkeyLabel then
    resetHotkeyButton:setEnabled(currentHotkeyLabel.status ~= HotkeyStatus.Applied)
    applyHotkeyButton:setEnabled(currentHotkeyLabel.status ~= HotkeyStatus.Applied)
    removeHotkeyButton:setEnabled(currentHotkeyLabel.status ~= HotkeyStatus.Deleted)
    hotkeyItemLabel:enable()
    currentItemPreview:setVisible(true)
    if currentHotkeyLabel.itemId ~= nil then
      hotkeyTextLabel:disable()
      hotkeyText:clearText()
      hotkeyText:disable()
      sendAutomatically:setChecked(false)
      sendAutomatically:disable()
      currentItemPreview:setIcon('')
      currentItemPreview:setItemId(currentHotkeyLabel.itemId)
      if currentHotkeyLabel.subType then
        currentItemPreview:setItemSubType(currentHotkeyLabel.subType)
      end

    elseif not GamePowerHotkeys.updateHotkeyForm(reset) then
      hotkeyTextLabel:enable()
      hotkeyText:enable()
      hotkeyText:focus()
      if reset then
        hotkeyText:setCursorPos(-1)
      end
      hotkeyText:setText(currentHotkeyLabel.value)
      sendAutomatically:setChecked(currentHotkeyLabel.autoSend)
      sendAutomatically:setEnabled(currentHotkeyLabel.value and #currentHotkeyLabel.value > 0)
      currentItemPreview:setIcon('')
      currentItemPreview:clearItem()
    end
  else
    removeHotkeyButton:disable()
    hotkeyTextLabel:disable()
    hotkeyText:disable()
    hotkeyText:clearText()
    sendAutomatically:disable()
    sendAutomatically:setChecked(false)
    hotkeyItemLabel:disable()
    currentItemPreview:setIcon('')
    currentItemPreview:clearItem()
    currentItemPreview:setVisible(false)
  end
end

function GameHotkeys.removeHotkey()
  if not currentHotkeyLabel then
    return
  end
  GameHotkeys.setStatus(currentHotkeyLabel, HotkeyStatus.Deleted)
  g_keyboard.unbindKeyPress(currentHotkeyLabel.keyCombo, boundCombosCallback[currentHotkeyLabel.keyCombo])
  boundCombosCallback[currentHotkeyLabel.keyCombo] = nil
end

function GameHotkeys.onHotkeyTextChange(value)
  if not hotkeysManagerLoaded then
    return
  end

  if not currentHotkeyLabel then
    return
  end

  currentHotkeyLabel.value = value
  local powerId = GamePowerHotkeys.getIdByString(currentHotkeyLabel.value)
  if value == '' then
    currentHotkeyLabel.autoSend = false
  elseif powerId then
    currentHotkeyLabel.autoSend = true
  end
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm()
  GameHotkeys.onEdit(currentHotkeyLabel)
end

function GameHotkeys.onSendAutomaticallyChange(autoSend)
  if not hotkeysManagerLoaded then
    return
  end

  if not currentHotkeyLabel then
    return
  end

  if not string.exists(currentHotkeyLabel.value) then
    return
  end

  currentHotkeyLabel.autoSend = autoSend
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm()
  GameHotkeys.onEdit(currentHotkeyLabel)
end

function GameHotkeys.onSelectHotkeyLabel(hotkeyLabel, unfocused)
  if hotkeyLabel then
    currentHotkeyLabel = hotkeyLabel
    currentHotkeyLabel:setBackgroundColor(currentHotkeyLabel.status.focusColor)
  end
  if unfocused then
    unfocused:setBackgroundColor(unfocused.status.color)
  end
  GameHotkeys.updateHotkeyForm(true)
end

function GameHotkeys.hotkeyCapture(assignWindow, keyCode, keyboardModifiers)
  local keyCombo = determineKeyComboDesc(keyCode, keyboardModifiers)
  local comboPreview = assignWindow:getChildById('comboPreview')
  comboPreview:setText(tr('Current hotkey to add') .. ': ' .. keyCombo)
  comboPreview.keyCombo = keyCombo
  comboPreview:resizeToText()
  assignWindow:getChildById('addButton'):enable()
  return true
end

function GameHotkeys.onEdit(hotkeyLabel)
  if not hotkeysManagerLoaded or hotkeyLabel.status == HotkeyStatus.Added or hotkeyLabel.status == HotkeyStatus.Deleted then
    return
  end
  local hotkey = hotkeyList[hotkeyLabel.keyCombo]
  if (not hotkeyLabel.autoSend ~= not hotkey.autoSend) or hotkeyLabel.itemId ~= hotkey.itemId or hotkeyLabel.subType ~= hotkey.subType or hotkeyLabel.useType ~= hotkey.useType then
    GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Edited)
  elseif (hotkey.value and hotkeyLabel.value ~= hotkey.value) or (not hotkey.value and string.exists(hotkeyLabel.value)) then
    GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Edited)
  else
    GameHotkeys.setStatus(hotkeyLabel, HotkeyStatus.Applied)
  end
end

function GameHotkeys.dragEnterItemPreview(self, mousePos)
  self:setBorderWidth(1)
  g_mouse.pushCursor('target')

  local powerId = GamePowerHotkeys.getIdByString(currentHotkeyLabel.value)
  local item    = self:getItem()
  if powerId then
    g_mouseicon.display(string.format('/images/ui/power/%d_off', powerId))
  elseif item and item:isPickupable() then
    g_mouseicon.displayItem(item)
  end

  return true
end

function GameHotkeys.dragLeaveItemPreview(self, droppedWidget, mousePos)
  g_mouseicon.hide()
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  GameHotkeys.clearObject()
  GameHotkeys.onEdit(currentHotkeyLabel)
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  return true
end

function GameHotkeys.dropOnItemPreview(self, widget, mousePos)
  if not currentHotkeyLabel then
    return false
  end

  local item = nil

  if not GamePowerHotkeys.dropOnItemPreview(self, widget, mousePos) then
    local widgetClass = widget:getClassName()
    if widgetClass == 'UIItem' then
      item = widget:getItem()
    elseif widgetClass == 'UIGameMap' then
      item = widget.currentDragThing
    end
  end

  if item then
    currentHotkeyLabel.itemId = item:getId()
    if item:isFluidContainer() then
        currentHotkeyLabel.subType = item:getSubType()
    end
    if item:isMultiUse() then
      currentHotkeyLabel.useType = HOTKEY_MANAGER_USEWITH
    else
      currentHotkeyLabel.useType = HOTKEY_MANAGER_USE
    end
    currentHotkeyLabel.value = nil
    currentHotkeyLabel.autoSend = false
  end
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)
  GameHotkeys.updateHotkeyForm(true)
  GameHotkeys.onEdit(currentHotkeyLabel)

  if modules.ka_game_hotkeybars then
    GameHotkeybars.onUpdateHotkeys()
  end
  return true
end
