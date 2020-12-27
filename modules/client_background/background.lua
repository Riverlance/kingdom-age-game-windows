_G.ClientBackground = { }



local background
local clientVersionLabel

function ClientBackground.init()
  -- Alias
  ClientBackground.m = modules.client_background

  background = g_ui.displayUI('background')
  background:lower()

  clientVersionLabel = background:getChildById('clientVersionLabel')
  clientVersionLabel:setText(string.format('%s\nVersion %s', g_app.getName(), CLIENT_VERSION))
  -- clientVersionLabel:setText(g_app.getName() .. --[[' ' .. g_app.getVersion() ..]] '\n' ..
  --                            'Version ' .. CLIENT_VERSION --[[.. '\n' ..
  --                            'Built on ' .. g_app.getBuildDate() .. ' for arch ' .. g_app.getBuildArch() .. '\n' .. g_app.getBuildCompiler()]])

  if not g_game.isOnline() then
    addEvent(function() g_effects.fadeIn(clientVersionLabel, 3000) end)
  end

  connect(g_game, {
    onGameStart = ClientBackground.hide
  })
  connect(g_game, {
    onGameEnd = ClientBackground.show
  })
end

function ClientBackground.terminate()
  disconnect(g_game, {
    onGameEnd = ClientBackground.show
  })
  disconnect(g_game, {
    onGameStart = ClientBackground.hide
  })

  g_effects.cancelFade(background:getChildById('clientVersionLabel'))
  background:destroy()

  background = nil

  _G.ClientBackground = nil
end

function ClientBackground.hide()
  background:hide()
end

function ClientBackground.show()
  background:show()
end

function ClientBackground.hideVersionLabel()
  background:getChildById('clientVersionLabel'):hide()
end

function ClientBackground.setVersionText(text)
  clientVersionLabel:setText(text)
end



function ClientBackground.getBackground()
  return background
end
