_G.GameShaders = { }



function GameShaders.init()
  -- Alias
  GameShaders.m = modules.game_shaders

  g_ui.importStyle('shaders.otui')

  if not g_graphics.canUseShaders() then
    return
  end

  for _, opts in pairs(MapShaders) do
    local shader = g_shaders.createFragmentShader(opts.name, opts.frag)

    if opts.tex1 then
      shader:addMultiTexture(opts.tex1)
    end
    if opts.tex2 then
      shader:addMultiTexture(opts.tex2)
    end
  end

  connect(g_game, {
    onGameStart = GameShaders.online,
  })
end

function GameShaders.terminate()
  disconnect(g_game, {
    onGameStart = GameShaders.online,
  })

  _G.GameShaders = nil
end

function GameShaders.online()
  setMapShader(ShaderFilter) -- Set to default shader
end
