_G.GamePlayerDeath = { }



deathWindow = nil

local deathTexts =
{
  regular = { text = 'Ouch! Brave adventurer, you have met a sad fate.\nBut do not despair, for the gods will bring you back\ninto this world in exchange for a small sacrifice.\n\nSimply click on Ok to resume your journeys!', height = 140, width = 0 },
  unfair = { text = 'Ouch! Brave adventurer, you have met a sad fate.\nBut do not despair, for the gods will bring you back\ninto this world in exchange for a small sacrifice.\n\nThis death penalty has been reduced by %i%%.\n\nSimply click on Ok to resume your journeys!', height = 185, width = 0 },
  blessed = { text = 'Ouch! Brave adventurer, you have met a sad fate.\nBut do not despair, for the gods will bring you back into this world.\n\nThis death penalty has been reduced by 100%%.\n\nSimply click on Ok to resume your journeys!', height = 170, width = 90 }
}



function GamePlayerDeath.init()
  -- Alias
  GamePlayerDeath.m = modules.game_npctrade

  g_ui.importStyle('deathwindow')

  connect(g_game, {
    onDeath   = GamePlayerDeath.display,
    onGameEnd = GamePlayerDeath.reset
  })
end

function GamePlayerDeath.terminate()
  disconnect(g_game, {
    onDeath   = GamePlayerDeath.display,
    onGameEnd = GamePlayerDeath.reset
  })

  GamePlayerDeath.reset()

  _G.GamePlayerDeath = nil
end

function GamePlayerDeath.reset()
  if deathWindow then
    deathWindow:destroy()
    deathWindow = nil
  end
end

function GamePlayerDeath.display(deathType, penalty)
  GamePlayerDeath.displayDeadMessage()
  GamePlayerDeath.openWindow(deathType, penalty)
end

function GamePlayerDeath.displayDeadMessage()
  local advanceLabel = GameInterface.getRootPanel():recursiveGetChildById('middleCenterLabel')
  if advanceLabel:isVisible() then
    return
  end

  if modules.game_textmessage then
    GameTextMessage.displayGameMessage(tr('You are dead') .. '.')
  end
end

function GamePlayerDeath.openWindow(deathType, penalty)
  if deathWindow then
    deathWindow:destroy()
    return
  end

  deathWindow = g_ui.createWidget('DeathWindow', rootWidget)

  local textLabel = deathWindow:getChildById('labelText')
  if deathType == DeathType.Regular then
    if penalty == 100 then
      textLabel:setText(tr(deathTexts.regular.text))
      deathWindow:setHeight(deathWindow.baseHeight + deathTexts.regular.height)
      deathWindow:setWidth(deathWindow.baseWidth + deathTexts.regular.width)
    else
      textLabel:setText(tr(deathTexts.unfair.text, 100 - penalty))
      deathWindow:setHeight(deathWindow.baseHeight + deathTexts.unfair.height)
      deathWindow:setWidth(deathWindow.baseWidth + deathTexts.unfair.width)
    end
  elseif deathType == DeathType.Blessed then
    textLabel:setText(tr(deathTexts.blessed.text))
    deathWindow:setHeight(deathWindow.baseHeight + deathTexts.blessed.height)
    deathWindow:setWidth(deathWindow.baseWidth + deathTexts.blessed.width)
  end

  local okButton = deathWindow:getChildById('buttonOk')
  local cancelButton = deathWindow:getChildById('buttonCancel')

  local okFunc = function()
    ClientCharacterList.doLogin()
    okButton:getParent():destroy()
    deathWindow = nil
  end
  local cancelFunc = function()
    g_game.safeLogout()
    cancelButton:getParent():destroy()
    deathWindow = nil
  end

  deathWindow.onEnter = okFunc
  deathWindow.onEscape = cancelFunc

  okButton.onClick = okFunc
  cancelButton.onClick = cancelFunc
end
