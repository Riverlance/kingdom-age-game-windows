_G.GamePowerHotkeys = { }



powerBoost_time    = 1000 -- Time difference between each boost
powerBoost_maxTime = 60 * 1000 -- boost_maxTime

powerBoost_lastPower     = 0
powerBoost_keyCombo      = nil
powerBoost_clickedWidget = nil
powerBoost_startAt       = nil

power_flag_start      = -1
power_flag_cancel     = -2
power_flag_updateList = -3 -- Used on ka_game_powers

-- Power Boost Effect

powerBoost_none  = 1
powerBoost_low   = 2
powerBoost_high  = 3
powerBoost_first = powerBoost_none
powerBoost_last  = powerBoost_high

powerBoost_fadein      = 400
powerBoost_fadeout     = 200
powerBoost_resizex     = 0.5
powerBoost_resizey     = 0.5
powerBoost_color_speed = 200

powerBoost_color_default = { r = 255, g = 255, b = 150 }
powerBoost_color =
{
  [powerBoost_none] = { r = 255, g = 255, b = 150 },
  [powerBoost_low]  = { r = 255, g = 150, b = 150 },
  [powerBoost_high] = { r = 150, g = 150, b = 255 }
}

powerBoost_state_color = false
powerBoost_event_color = nil
powerBoost_state_image = false
powerBoost_event_image = nil

-- Hotkeys

HotkeyColors.powerColor = '#CD4EFF'



function GamePowerHotkeys.init()
  -- Alias
  GamePowerHotkeys.m = modules.game_hotkeys

  g_keyboard.bindKeyPress('Escape', function() GamePowerHotkeys.cancel(true) end, rootWidget)

  GamePowerHotkeys.removeBoostEffect()
end

function GamePowerHotkeys.terminate()
  GamePowerHotkeys.removeBoostEffect()

  _G.GamePowerHotkeys = nil
end

function GamePowerHotkeys.getIdByString(str)
  str = str and tostring(str) or ''
  return tonumber(str:match('/power (%d+)'))
end

function GamePowerHotkeys.send(flag, keyCombo) -- ([flag], [keyCombo]) -- (flag: powerFlags)
  local mapWidget = GameInterface.getMapPanel()
  if not mapWidget then
    return
  end

  local toPos = mapWidget:getPosition(g_window.getMousePosition())

  GamePowerHotkeys.removeBoostEffect()

  -- If has flag, send flag instead of power id
  if flag then
    g_game.sendPowerBuffer(string.format("%d:%d:%d:%d", flag, 0, 0, 0))
    return
  end

  -- Send power id and mouse position
  g_game.sendPowerBuffer(string.format("%d:%d:%d:%d", powerBoost_lastPower, toPos.x, toPos.y, toPos.z))

  if keyCombo then
    if modules.ka_game_hotkeybars and lastHotkeyTime > 0 then
      local boostTime  = g_clock.millis() - lastHotkeyTime
      local boostLevel = math.min(math.max(powerBoost_first, math.ceil(boostTime / powerBoost_time)), powerBoost_last)
      GameHotkeybars.addPowerSendingHotkeyEffect(keyCombo, boostLevel)
    end
  end
end

function GamePowerHotkeys.sendBoostStart()
  GamePowerHotkeys.send(power_flag_start)
  GamePowerHotkeys.addBoostEffect()
end

function GamePowerHotkeys.cancel(forceStop)
  if not g_game.isOnline() then
    return
  end

  GamePowerHotkeys.send(power_flag_cancel)
  GamePowerHotkeys.removeBoostEffect()

  if modules.ka_game_hotkeybars then
    GameHotkeybars.setPowerIcon(powerBoost_keyCombo, false)
  end

  if forceStop then
    powerBoost_lastPower = -1
    scheduleEvent(function() powerBoost_lastPower = 0 end, 1000)
  else
    powerBoost_lastPower = 0
  end

  if powerBoost_clickedWidget then
    disconnect(powerBoost_clickedWidget, 'onMouseRelease')
  else
    if powerBoost_keyCombo then
      g_keyboard.unbindKeyUp(powerBoost_keyCombo)
    end
  end

  powerBoost_keyCombo      = nil
  powerBoost_clickedWidget = nil
  powerBoost_startAt       = nil
end

function GamePowerHotkeys.removeBoostColor()
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  powerBoost_state_color = false
  localPlayer:setColor(0, 0, 0, 0)

  if powerBoost_event_color then
    removeEvent(powerBoost_event_color)
    powerBoost_event_color = nil
  end
end

function GamePowerHotkeys.removeBoostImage()
  powerBoost_state_image = false
  if modules.ka_game_screenimage then
    for boostLevel = powerBoost_first, powerBoost_last do
      GameScreenImage.removeImage(string.format("system/power_boost/normal_%d.png", boostLevel), powerBoost_fadeout, 0)
      GameScreenImage.removeImage(string.format("system/power_boost/extra_%d.png", boostLevel), powerBoost_fadeout, 0)
    end
  end

  if powerBoost_event_image then
    removeEvent(powerBoost_event_image)
    powerBoost_event_image = nil
  end
end

function GamePowerHotkeys.setBoostColor(boostTime, light) -- ([boostTime[, light]])
  local localPlayer = g_game.getLocalPlayer()
  if not localPlayer then
    return
  end

  local boostLevel = powerBoost_first

  boostTime  = boostTime and boostTime + powerBoost_color_speed or 0
  light      = light == nil and true or not light
  boostLevel = math.min(math.max(powerBoost_first, math.ceil(boostTime / powerBoost_time)), powerBoost_last)

  if boostTime == 0 then
    GamePowerHotkeys.removeBoostColor()
    powerBoost_state_color = true
  end

  local ret = false
  if powerBoost_state_color then
    localPlayer:setColor(powerBoost_color[boostLevel].r or powerBoost_color_default.r, powerBoost_color[boostLevel].g or powerBoost_color_default.g, powerBoost_color[boostLevel].b or powerBoost_color_default.b, light and 255 or 0)
    powerBoost_event_color = scheduleEvent(function() GamePowerHotkeys.setBoostColor(boostTime, light) end, powerBoost_color_speed)
    ret = true
  end
  return ret
end

function GamePowerHotkeys.setBoostImage(boostTime) -- ([boostTime])
  local boostLevel = powerBoost_first

  boostTime  = boostTime and boostTime + powerBoost_time or 0
  boostLevel = math.min(math.max(powerBoost_first, math.ceil(boostTime / powerBoost_time)), powerBoost_last)

  if boostLevel == 1 then
    GamePowerHotkeys.removeBoostImage()
    powerBoost_state_image = true
  else
    if modules.ka_game_screenimage then
      GameScreenImage.removeImage(string.format("system/power_boost/normal_%d.png", boostLevel - 1), powerBoost_fadeout, 0)
      GameScreenImage.removeImage(string.format("system/power_boost/extra_%d.png", boostLevel - 1), powerBoost_fadeout, 0)
    end
  end

  local ret = false
  if powerBoost_state_image then
    if modules.ka_game_screenimage and boostTime ~= 0 then
      GameScreenImage.addImage(string.format("system/power_boost/normal_%d.png", boostLevel), powerBoost_fadein, 1, powerBoost_resizex, powerBoost_resizey, 0)
      GameScreenImage.addImage(string.format("system/power_boost/extra_%d.png", boostLevel), powerBoost_fadein, 1, powerBoost_resizex, powerBoost_resizey, 0)
    end

    powerBoost_event_image = scheduleEvent(function() GamePowerHotkeys.setBoostImage(boostTime) end, boostTime ~= 0 and powerBoost_time or 0)
    ret = true
  end
  return ret
end

function GamePowerHotkeys.removeBoostEffect()
  GamePowerHotkeys.removeBoostColor()
  GamePowerHotkeys.removeBoostImage()
end

function GamePowerHotkeys.addBoostEffect()
  GamePowerHotkeys.setBoostColor()
  GamePowerHotkeys.setBoostImage()
end



-- Hotkeys

function GamePowerHotkeys.unload()
  GamePowerHotkeys.removeBoostEffect()
end

function GamePowerHotkeys.doKeyCombo(keyCombo, clickedWidget, params)
  local powerId = GamePowerHotkeys.getIdByString(params.hotkey.value)
  if not powerId then
    return
  end

  -- Should not work with right button because onMouseRelease is not working with the right mouse button
  if clickedWidget and g_mouse.isPressed(MouseRightButton) then
    return
  end

  -- No previous power
  if powerBoost_lastPower == 0 then
    powerBoost_lastPower = tonumber(powerId) or 0
    powerBoost_keyCombo  = keyCombo
    powerBoost_startAt   = params.actualTime

    GamePowerHotkeys.sendBoostStart()

    if modules.ka_game_hotkeybars then
      GameHotkeybars.setPowerIcon(powerBoost_keyCombo, true)
    end

    -- By mouse click
    if clickedWidget then
      powerBoost_clickedWidget = clickedWidget

      connect(clickedWidget, {
        onMouseRelease = function(widget, mousePos, mouseButton, elapsedTime)
          -- Should not work with right button because onMouseRelease is not working with the right mouse button
          if g_mouse.isPressed(MouseLeftButton) then -- If right released and left kept pressed
            return
          elseif not widget:containsPoint(mousePos) then
            GamePowerHotkeys.cancel()
            return
          end

          GamePowerHotkeys.send(nil, powerBoost_keyCombo)

          disconnect(clickedWidget, 'onMouseRelease')

          if modules.ka_game_hotkeybars then
            GameHotkeybars.setPowerIcon(powerBoost_keyCombo, false)
          end

          scheduleEvent(function()
            powerBoost_lastPower = 0
            powerBoost_keyCombo = nil
          end, 500)
        end
      })

    -- By keyboard press
    else
      g_keyboard.bindKeyUp(keyCombo, function ()
        g_keyboard.unbindKeyUp(keyCombo)

        GamePowerHotkeys.send(nil, powerBoost_keyCombo)

        if modules.ka_game_hotkeybars then
          GameHotkeybars.setPowerIcon(powerBoost_keyCombo, false)
        end

        scheduleEvent(function()
          powerBoost_lastPower = 0
          powerBoost_keyCombo = nil
        end, 500)
      end)
    end

  -- Has previous power
  elseif powerBoost_lastPower > 0 then
    local elapsedTime = params.actualTime - powerBoost_startAt
    if elapsedTime > powerBoost_maxTime then
      GamePowerHotkeys.cancel(true)
    end
  end
end

function GamePowerHotkeys.getHotkey(keyCombo, params)
  -- if not hotkey.autoSend then
  --   return nil
  -- end

  local powerId = GamePowerHotkeys.getIdByString(params.hotkey.value)
  if not powerId then
    return nil
  end

  local ret = { type = 'power', id = powerId }

  if modules.ka_game_powers then
    local power = GamePowers.getPower(powerId)
    if power then
      ret.name  = power.name
      ret.level = power.level
    end
  end

  return ret
end

function GamePowerHotkeys.updateHotkeyLabel(hotkeyLabel, params)
  if not hotkeyLabel.value then
    return false
  end

  local powerId = GamePowerHotkeys.getIdByString(hotkeyLabel.value)
  if not powerId then
    return false
  end

  local power = modules.ka_game_powers and GamePowers.getPower(powerId) or nil
  local name, level
  if power then
    name  = power.name
    level = power.level
  end

  hotkeyLabel:setText(string.format("%s[Power] %s", params.text, name and string.format('%s%s', name, level and string.format(' (level %d)', level) or '') or 'You are not able to use this power.'))

  if powerId then
    hotkeyLabel:setColor(HotkeyColors.powerColor)
  end

  return true
end

function GamePowerHotkeys.updateHotkeyForm(reset)
  if not currentHotkeyLabel then
    return false
  end

  local powerId = GamePowerHotkeys.getIdByString(currentHotkeyLabel.value)
  if not powerId then
    return false
  end

  local oldValue = currentHotkeyLabel.value
  hotkeyTextLabel:disable()
  hotkeyText:clearText()
  hotkeyText:disable()
  sendAutomatically:setChecked(true)
  sendAutomatically:disable()
  currentItemPreview:setIcon('/images/ui/power/' .. powerId .. '_off')

  -- Keeps hotkeyText invisible
  currentHotkeyLabel.value = oldValue
  GameHotkeys.updateHotkeyLabel(currentHotkeyLabel)

  return true
end

function GamePowerHotkeys.dropOnItemPreview(self, widget, mousePos)
  local widgetClass = widget:getClassName()

  if widgetClass == 'UIPowerButton' then
    local powerId = widget.power.id
    currentHotkeyLabel.itemId = nil
    currentHotkeyLabel.value = '/power ' .. powerId
    currentHotkeyLabel.autoSend = true
    currentHotkeyLabel.useType = nil
    return true
  end
  return false
end
