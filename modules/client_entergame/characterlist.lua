_G.ClientCharacterList = { }



local charactersWindow
local loadBox
local characterList
local errorBox
local waitingWindow
local updateWaitEvent
local resendWaitEvent
local loginEvent



local function tryLogin(charInfo, tries)
  tries = tries or 1

  if tries > 50 then
    return
  end

  if g_game.isOnline() then
    if tries == 1 then
      g_game.safeLogout()
    end
    loginEvent = scheduleEvent(function() tryLogin(charInfo, tries+1) end, 100)
    return
  end

  ClientCharacterList.hide()

  g_game.loginWorld(G.account, G.password, charInfo.worldName, charInfo.worldHost, charInfo.worldPort, charInfo.characterName, G.authenticatorToken, G.sessionKey)

  loadBox = displayCancelBox(tr('Loading'), tr('Connecting to game server...'))
  connect(loadBox, {
    onCancel = function()
      loadBox = nil
      g_game.cancelLogin()
      ClientCharacterList.show()
    end
  })

  -- save last used character
  g_settings.set('last-used-character', charInfo.characterName)
  g_settings.set('last-used-world', charInfo.worldName)
end

local function updateWait(timeStart, timeEnd)
  if waitingWindow then
    local time = g_clock.seconds()
    if time <= timeEnd then
      local percent = ((time - timeStart) / (timeEnd - timeStart)) * 100
      local timeStr = string.format("%.0f", timeEnd - time)

      local progressBar = waitingWindow:getChildById('progressBar')
      progressBar:setPercent(percent)

      local label = waitingWindow:getChildById('timeLabel')
      label:setText(tr('Trying to reconnect in %s seconds.', timeStr))

      updateWaitEvent = scheduleEvent(function() updateWait(timeStart, timeEnd) end, 1000 * progressBar:getPercentPixels() / 100 * (timeEnd - timeStart))
      return true
    end
  end

  if updateWaitEvent then
    updateWaitEvent:cancel()
    updateWaitEvent = nil
  end
end

local function resendWait()
  if waitingWindow then
    waitingWindow:destroy()
    waitingWindow = nil

    if updateWaitEvent then
      updateWaitEvent:cancel()
      updateWaitEvent = nil
    end

    if charactersWindow then
      local selected = characterList:getFocusedChild()
      if selected then
        local charInfo = { worldHost = selected.worldHost,
                           worldPort = selected.worldPort,
                           worldName = selected.worldName,
                           characterName = selected.characterName }
        tryLogin(charInfo)
      end
    end
  end
end

local function onLoginWait(message, time)
  ClientCharacterList.destroyLoadBox()

  waitingWindow = g_ui.displayUI('waitinglist')

  local label = waitingWindow:getChildById('infoLabel')
  label:setText(message)

  updateWaitEvent = scheduleEvent(function() updateWait(g_clock.seconds(), g_clock.seconds() + time) end, 0)
  resendWaitEvent = scheduleEvent(resendWait, time * 1000)
end



function onGameLoginError(message)
  ClientCharacterList.destroyLoadBox()
  errorBox = displayErrorBox(tr("Login Error"), message)
  errorBox.onOk = function()
    errorBox = nil
    ClientCharacterList.showAgain()
  end
end

function onGameLoginToken(unknown)
  ClientCharacterList.destroyLoadBox()
  -- TODO: make it possible to enter a new token here / prompt token
  errorBox = displayErrorBox(tr("Two-Factor Authentication"), tr('A new authentication token is required.\nLogin again.'))
  errorBox.onOk = function()
    errorBox = nil
    ClientEnterGame.show()
  end
end

function onGameConnectionError(message, code)
  ClientCharacterList.destroyLoadBox()
  local text = translateNetworkError(code, g_game.getProtocolGame() and g_game.getProtocolGame():isConnecting(), message)
  errorBox = displayErrorBox(tr("Connection Error"), text)
  errorBox.onOk = function()
    errorBox = nil
    ClientCharacterList.showAgain()
  end
end

function onGameUpdateNeeded(signature)
  ClientCharacterList.destroyLoadBox()
  errorBox = displayErrorBox(tr("Update needed"), tr('Enter with your account again to update your client.'))
  errorBox.onOk = function()
    errorBox = nil
    ClientCharacterList.showAgain()
  end
end



function ClientCharacterList.init()
  -- Alias
  ClientCharacterList.m = modules.client_entergame

  connect(g_game, {
    onLoginError = onGameLoginError,
    onLoginToken = onGameLoginToken,
    onUpdateNeeded = onGameUpdateNeeded,
    onConnectionError = onGameConnectionError,
    onGameStart = ClientCharacterList.destroyLoadBox,
    onLoginWait = onLoginWait,
    onGameEnd = ClientCharacterList.showAgain,
    onLoginnameChange = ClientCharacterList.updateLoginname
  })

  if G.characters then
    ClientCharacterList.create(G.characters, G.characterAccount)
  end
end

function ClientCharacterList.terminate()
  disconnect(g_game, {
    onLoginError = onGameLoginError,
    onLoginToken = onGameLoginToken,
    onUpdateNeeded = onGameUpdateNeeded,
    onConnectionError = onGameConnectionError,
    onGameStart = ClientCharacterList.destroyLoadBox,
    onLoginWait = onLoginWait,
    onGameEnd = ClientCharacterList.showAgain,
    onLoginnameChange = ClientCharacterList.updateLoginname
  })

  if charactersWindow then
    characterList = nil
    charactersWindow:destroy()
    charactersWindow = nil
  end

  if loadBox then
    g_game.cancelLogin()
    loadBox:destroy()
    loadBox = nil
  end

  if waitingWindow then
    waitingWindow:destroy()
    waitingWindow = nil
  end

  if updateWaitEvent then
    removeEvent(updateWaitEvent)
    updateWaitEvent = nil
  end

  if resendWaitEvent then
    removeEvent(resendWaitEvent)
    resendWaitEvent = nil
  end

  if loginEvent then
    removeEvent(loginEvent)
    loginEvent = nil
  end

  _G.ClientCharacterList = nil
end

function ClientCharacterList.create(characters, account, otui)
  if not otui then
    otui = 'characterlist'
  end

  if charactersWindow then
    charactersWindow:destroy()
  end

  charactersWindow = g_ui.displayUI(otui)
  characterList = charactersWindow:getChildById('characters')

  -- characters
  G.characters = characters
  G.characterAccount = account

  characterList:destroyChildren()
  local accountStatusLabel = charactersWindow:getChildById('accountStatusLabel')

  local focusLabel
  for i,characterInfo in ipairs(characters) do
    local widget = g_ui.createWidget('CharacterWidget', characterList)
    widget.name = characterInfo.name
    widget.loginname = characterInfo.loginname
    for key,value in pairs(characterInfo) do
      local subWidget = widget:getChildById(key)
      if subWidget then
        if key == 'name' and characterInfo.loginname ~= '' then
          value = characterInfo.loginname
        end

        if key == 'outfit' then -- it's an exception
          subWidget:setOutfit(value)
        else
          local text = value
          if subWidget.baseText and subWidget.baseTranslate then
            text = tr(subWidget.baseText, text)
          elseif subWidget.baseText then
            text = string.format(subWidget.baseText, text)
          end
          subWidget:setText(text)
        end
      end
    end

    -- these are used by login
    widget.characterName = characterInfo.name
    widget.worldName = characterInfo.worldName
    widget.worldHost = characterInfo.worldIp
    widget.worldPort = characterInfo.worldPort

    connect(widget, {
      onDoubleClick = function()
        ClientCharacterList.doLogin()
        return true
      end
    })

    if i == 1 or (g_settings.get('last-used-character') == widget.characterName and g_settings.get('last-used-world') == widget.worldName) then
      focusLabel = widget
    end
  end

  if focusLabel then
    characterList:focusChild(focusLabel, KeyboardFocusReason)
    addEvent(function() characterList:ensureChildVisible(focusLabel) end)
  end

  -- account
  if account.premDays >= 1 and account.premDays < 65535 then
    accountStatusLabel:setText(tr("Premium Account - Days left") .. ": " .. account.premDays)
  elseif account.premDays >= 65535 then
    accountStatusLabel:setText(tr("Lifetime Premium Account"))
  else
    accountStatusLabel:setText(tr('Free Account'))
  end

  if account.premDays >= 1 and account.premDays <= 7 then
    accountStatusLabel:setOn(true)
  else
    accountStatusLabel:setOn(false)
  end
end

function ClientCharacterList.destroy()
  ClientCharacterList.hide(true)

  if charactersWindow then
    characterList = nil
    charactersWindow:destroy()
    charactersWindow = nil
  end
end

function ClientCharacterList.show()
  if loadBox or errorBox or not charactersWindow then
    return
  end

  charactersWindow:show()
  charactersWindow:raise()
  charactersWindow:focus()
  ClientEnterGame.toggleLoginButton(true)
end

function ClientCharacterList.hide(showLogin)
  showLogin = showLogin or false
  if charactersWindow then
    charactersWindow:hide()
    ClientEnterGame.toggleLoginButton(false)
  end

  if showLogin and not g_game.isOnline() then
    ClientEnterGame.show()
  end
end

function ClientCharacterList.showAgain()
  if characterList and characterList:hasChildren() then
    ClientCharacterList.show()
  end
end

function ClientCharacterList.isVisible()
  if charactersWindow and charactersWindow:isVisible() then
    return true
  end
  return false
end

function ClientCharacterList.doLogin()
  local selected = characterList:getFocusedChild()
  if selected then
    local charInfo =
    {
      worldHost     = selected.worldHost,
      worldPort     = selected.worldPort,
      worldName     = selected.worldName,
      characterName = selected.characterName
    }
    charactersWindow:hide()
    ClientEnterGame.toggleLoginButton(false)

    if loginEvent then
      removeEvent(loginEvent)
      loginEvent = nil
    end
    tryLogin(charInfo)
  else
    displayErrorBox(tr('Error'), tr('You must select a character to login.'))
  end
end

function ClientCharacterList.destroyLoadBox()
  if loadBox then
    loadBox:destroy()
    loadBox = nil
  end
end

function ClientCharacterList.cancelWait()
  if waitingWindow then
    waitingWindow:destroy()
    waitingWindow = nil
  end

  if updateWaitEvent then
    removeEvent(updateWaitEvent)
    updateWaitEvent = nil
  end

  if resendWaitEvent then
    removeEvent(resendWaitEvent)
    resendWaitEvent = nil
  end

  ClientCharacterList.destroyLoadBox()
  ClientCharacterList.showAgain()
end

function ClientCharacterList.updateLoginname(name, currentLoginname, newLoginname)
  local children = characterList:getChildren()
  if #children > 0 then
    for i = 1, #children do
      if children[i].name:lower() == name:lower() and children[i].loginname:lower() == currentLoginname:lower() then
        children[i].loginname = newLoginname
        if newLoginname == "" then
          children[i]:getChildById('name'):setText(children[i].name)
        else
          children[i]:getChildById('name'):setText(newLoginname)
        end
      end
    end
  end
end
