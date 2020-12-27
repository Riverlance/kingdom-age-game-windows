_G.ClientDev = { }



local developmentWindow
local localCheckBox
local devCheckBox
local drawBoxesCheckBox
local hideMapCheckBox

local tempIp              = ClientEnterGame.clientIp
local tempPort            = ClientEnterGame.clientPort
local tempProtocolVersion = ClientEnterGame.clientProtocolVersion

local hasLoggedOnce = false



local function onServerChange(self)
  if not localCheckBox:isChecked() or not devCheckBox:isChecked() then
    return
  end

  if self == localCheckBox then
    devCheckBox:setChecked(false)
  else
    localCheckBox:setChecked(false)
  end
end

local function onLocalCheckBoxChange(self, value)
  tempIp = value and ClientEnterGame.localIp or ClientEnterGame.clientIp

  ClientEnterGame.setUniqueServer(tempIp, tempPort, tempProtocolVersion)

  onServerChange(self)
end

local function onDevCheckBoxChange(self, value)
  tempPort = value and '7175' or '7171'

  ClientEnterGame.setUniqueServer(tempIp, tempPort, tempProtocolVersion)

  onServerChange(self)
end

local function onDrawBoxesCheckBoxChange(self, value)
  draw_debug_boxes(value)
end

local function onHideMapCheckBoxChange(self, value)
  if value then
    hide_map()
  else
    show_map()
  end
end

local function onGameStart()
  hasLoggedOnce = true
end



function ClientDev.init()
  -- Alias
  ClientDev.m = modules.ka_client_dev

  ClientDev.reconnectToDefaultServer()

  developmentWindow = g_ui.displayUI('dev')
  localCheckBox     = developmentWindow:getChildById('localCheckBox')
  devCheckBox       = developmentWindow:getChildById('devCheckBox')
  drawBoxesCheckBox = developmentWindow:getChildById('drawBoxesCheckBox')
  hideMapCheckBox   = developmentWindow:getChildById('hideMapCheckBox')

  -- Setup window
  developmentWindow:breakAnchors()
  developmentWindow:hide()
  developmentWindow:move(200, 200)

  -- Bind key
  g_keyboard.bindKeyDown('Ctrl+Alt+D', ClientDev.toggleWindow)

  -- Connect
  connect(g_game, {
    onGameStart = onGameStart,
  })
  connect(localCheckBox, {
    onCheckChange = onLocalCheckBoxChange
  })
  connect(devCheckBox, {
    onCheckChange = onDevCheckBoxChange
  })
  connect(drawBoxesCheckBox, {
    onCheckChange = onDrawBoxesCheckBoxChange
  })
  connect(hideMapCheckBox, {
    onCheckChange = onHideMapCheckBoxChange
  })
end

function ClientDev.terminate()
  -- Disconnect
  disconnect(hideMapCheckBox, {
    onCheckChange = onHideMapCheckBoxChange
  })
  disconnect(drawBoxesCheckBox, {
    onCheckChange = onDrawBoxesCheckBoxChange
  })
  disconnect(devCheckBox, {
    onCheckChange = onDevCheckBoxChange
  })
  disconnect(localCheckBox, {
    onCheckChange = onLocalCheckBoxChange
  })
  disconnect(g_game, {
    onGameStart = onGameStart,
  })

  -- Unbind key
  g_keyboard.unbindKeyDown('Ctrl+Alt+D')

  -- Destroy window
  if developmentWindow then
    developmentWindow:destroy()
    developmentWindow = nil
  end
  localCheckBox     = nil
  devCheckBox       = nil
  drawBoxesCheckBox = nil
  hideMapCheckBox   = nil

  ClientDev.reconnectToDefaultServer()

  _G.ClientDev = nil
end



function ClientDev.reconnectToDefaultServer()
  tempIp              = ClientEnterGame.clientIp
  tempPort            = ClientEnterGame.clientPort
  tempProtocolVersion = ClientEnterGame.clientProtocolVersion

  ClientEnterGame.setUniqueServer(tempIp, tempPort, tempProtocolVersion)
end

function ClientDev.toggleWindow()
  if developmentWindow:isHidden() then
    developmentWindow:show()

    -- Connect to local server by default
    if not hasLoggedOnce then
      localCheckBox:setChecked(true)
    end
  else
    developmentWindow:hide()
  end
end
