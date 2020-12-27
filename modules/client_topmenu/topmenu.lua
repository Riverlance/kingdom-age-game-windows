_G.ClientTopMenu = { }



local topMenu
local leftButtonsPanel
local rightButtonsPanel
local leftGameButtonsPanel
local rightGameButtonsPanel



local function addButton(id, description, icon, callback, panel, toggle, front)
  local class
  if toggle then
    class = 'TopToggleButton'
  else
    class = 'TopButton'
  end

  local button = panel:getChildById(id)
  if not button then
    button = g_ui.createWidget(class)
    if front then
      panel:insertChild(1, button)
    else
      panel:addChild(button)
    end
  end
  button:setId(id)
  button:setTooltip(description)
  button:setIcon(resolvepath(icon, 3))
  button.onMouseRelease = function(widget, mousePos, mouseButton)
    if widget:containsPoint(mousePos) and mouseButton ~= MouseMidButton then
      callback()
      return true
    end
  end
  return button
end



function ClientTopMenu.init()
  -- Alias
  ClientTopMenu.m = modules.client_topmenu

  connect(g_game, {
    onGameStart = ClientTopMenu.online,
    onGameEnd   = ClientTopMenu.offline,
    onPingBack  = ClientTopMenu.updatePing
  })
  connect(g_app, {
    onFps = ClientTopMenu.updateFps
  })

  topMenu = g_ui.displayUI('topmenu')

  leftButtonsPanel = topMenu:getChildById('leftButtonsPanel')
  rightButtonsPanel = topMenu:getChildById('rightButtonsPanel')
  leftGameButtonsPanel = topMenu:getChildById('leftGameButtonsPanel')
  rightGameButtonsPanel = topMenu:getChildById('rightGameButtonsPanel')
  pingLabel = topMenu:getChildById('pingLabel')
  fpsLabel = topMenu:getChildById('fpsLabel')

  if g_game.isOnline() then
    ClientTopMenu.online()
  end
end

function ClientTopMenu.terminate()
  disconnect(g_app, {
    onFps = ClientTopMenu.updateFps
  })
  disconnect(g_game, {
    onGameStart = ClientTopMenu.online,
    onGameEnd   = ClientTopMenu.offline,
    onPingBack  = ClientTopMenu.updatePing
  })

  topMenu:destroy()

  _G.ClientTopMenu = nil
end



function ClientTopMenu.online()
  ClientTopMenu.showGameButtons()

  addEvent(function()
    if ClientOptions.getOption('showPing') and g_game.getFeature(GameClientPing) then
      pingLabel:show()
    else
      pingLabel:hide()
    end
  end)
end

function ClientTopMenu.offline()
  ClientTopMenu.hideGameButtons()
  pingLabel:hide()
end

function ClientTopMenu.updateFps(fps)
  text = 'FPS: ' .. fps
  fpsLabel:setText(text)
end

function ClientTopMenu.updatePing(ping) -- See UICreatureButton:updatePing
  local text = 'Ping: '
  local color

  -- Unknown
  if ping < 0 then
    text  = text .. '?'
    color = 'yellow'

  -- Known
  else
    text = text .. ping .. ' ms'

    if ping >= 500 then
      color = 'red'

    elseif ping >= 250 then
      color = 'yellow'

    else
      color = 'green'
    end
  end

  pingLabel:setText(text)
  pingLabel:setColor(color)
end

function ClientTopMenu.setPingVisible(enable)
  pingLabel:setVisible(enable)
end

function ClientTopMenu.setFpsVisible(enable)
  fpsLabel:setVisible(enable)
end

function ClientTopMenu.addLeftButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, false, front)
end

function ClientTopMenu.addLeftToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftButtonsPanel, true, front)
end

function ClientTopMenu.addRightButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, false, front)
end

function ClientTopMenu.addRightToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightButtonsPanel, true, front)
end

function ClientTopMenu.addLeftGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, false, front)
end

function ClientTopMenu.addLeftGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, leftGameButtonsPanel, true, front)
end

function ClientTopMenu.addRightGameButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, false, front)
end

function ClientTopMenu.addRightGameToggleButton(id, description, icon, callback, front)
  return addButton(id, description, icon, callback, rightGameButtonsPanel, true, front)
end

function ClientTopMenu.showGameButtons()
  leftGameButtonsPanel:show()
  rightGameButtonsPanel:show()
end

function ClientTopMenu.hideGameButtons()
  leftGameButtonsPanel:hide()
  rightGameButtonsPanel:hide()
end

function ClientTopMenu.getButton(id)
  return topMenu:recursiveGetChildById(id)
end

function ClientTopMenu.getTopMenu()
  return topMenu
end
