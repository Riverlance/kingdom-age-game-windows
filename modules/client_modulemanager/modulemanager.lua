_G.ClientModuleManager = { }



local moduleManagerWindow
local moduleManagerButton
local moduleList



function ClientModuleManager.init()
  -- Alias
  ClientModuleManager.m = modules.client_modulemanager

  moduleManagerWindow = g_ui.displayUI('modulemanager')
  moduleManagerWindow:hide()
  moduleList = moduleManagerWindow:getChildById('moduleList')
  connect(moduleList, {
    onChildFocusChange = function(self, focusedChild)
      if focusedChild == nil then
        return
      end

      ClientModuleManager.updateModuleInfo(focusedChild:getText())
    end
  })

  g_keyboard.bindKeyPress('Up', function() moduleList:focusPreviousChild(KeyboardFocusReason) end, moduleManagerWindow)
  g_keyboard.bindKeyPress('Down', function() moduleList:focusNextChild(KeyboardFocusReason) end, moduleManagerWindow)

  --moduleManagerButton = ClientTopMenu.addLeftButton('moduleManagerButton', tr('Module Manager') .. ' (Ctrl+Alt+T)', '/images/ui/top_menu/modulemanager', ClientModuleManager.toggle)

  g_keyboard.bindKeyDown('Ctrl+Alt+T', ClientModuleManager.toggle)

  -- refresh modules only after all modules are loaded
  addEvent(ClientModuleManager.listModules)
end

function ClientModuleManager.terminate()
  g_keyboard.unbindKeyDown('Ctrl+Alt+T')

  moduleManagerWindow:destroy()
  if moduleManagerButton then
    moduleManagerButton:destroy()
  end
  moduleList = nil

  _G.ClientModuleManager = nil
end

function ClientModuleManager.disable()
  if moduleManagerButton then
    moduleManagerButton:hide()
  end
end

function ClientModuleManager.hide()
  moduleManagerWindow:hide()
  if moduleManagerButton then
    moduleManagerButton:setOn(false)
  end
end

function ClientModuleManager.show()
  if not g_game.isOnline() or g_game.getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
    return
  end

  moduleManagerWindow:show()
  moduleManagerWindow:raise()
  moduleManagerWindow:focus()
  if moduleManagerButton then
    moduleManagerButton:setOn(true)
  end
end

function ClientModuleManager.toggle()
  if moduleManagerWindow:isVisible() then
    ClientModuleManager.hide()
  else
    ClientModuleManager.show()
  end
end

function ClientModuleManager.refreshModules()
  g_modules.discoverModules()
  ClientModuleManager.listModules()
end

function ClientModuleManager.listModules()
  if not moduleManagerWindow then
    return
  end

  moduleList:destroyChildren()

  local modules = g_modules.getModules()
  for i,module in ipairs(modules) do
    local label = g_ui.createWidget('ModuleListLabel', moduleList)
    label:setText(module:getName())
    label:setOn(module:isLoaded())
  end

  moduleList:focusChild(moduleList:getFirstChild(), ActiveFocusReason)
end

function ClientModuleManager.refreshLoadedModules()
  if not moduleManagerWindow then
    return
  end

  for i,child in ipairs(moduleList:getChildren()) do
    local module = g_modules.getModule(child:getText())
    child:setOn(module:isLoaded())
  end
end

function ClientModuleManager.updateModuleInfo(moduleName)
  if not moduleManagerWindow then
    return
  end

  local name = ''
  local description = ''
  local autoLoad = ''
  local author = ''
  local website = ''
  local version = ''
  local loaded = false
  local canReload = false
  local canUnload = false

  local module = g_modules.getModule(moduleName)
  if module then
    name = module:getName()
    description = module:getDescription()
    author = module:getAuthor()
    website = module:getWebsite()
    version = module:getVersion()
    loaded = module:isLoaded()
    canReload = module:canReload()
    canUnload = module:canUnload()
  end

  local moduleInfoPanel = moduleManagerWindow:getChildById('moduleInfo')

  moduleInfoPanel:getChildById('moduleName'):setText(name)
  moduleInfoPanel:getChildById('moduleDescription'):setText(description)
  moduleInfoPanel:getChildById('moduleAuthor'):setText(author)
  moduleInfoPanel:getChildById('moduleWebsite'):setText(website)
  moduleInfoPanel:getChildById('moduleVersion'):setText(version)

  local reloadButton = moduleManagerWindow:getChildById('moduleReloadButton')
  reloadButton:setEnabled(canReload)
  if loaded then reloadButton:setText(tr('Reload'))
  else reloadButton:setText(tr('Load')) end

  local unloadButton = moduleManagerWindow:getChildById('moduleUnloadButton')
  unloadButton:setEnabled(canUnload)
end

function ClientModuleManager.reloadCurrentModule()
  local focusedChild = moduleList:getFocusedChild()
  if focusedChild then
    local module = g_modules.getModule(focusedChild:getText())
    if module then
      module:reload()
      if modules.client_modulemanager then
        ClientModuleManager.updateModuleInfo(module:getName())
        ClientModuleManager.refreshLoadedModules()
        ClientModuleManager.show()
      end
    end
  end
end

function ClientModuleManager.unloadCurrentModule()
  local focusedChild = moduleList:getFocusedChild()
  if focusedChild then
    local module = g_modules.getModule(focusedChild:getText())
    if module then
      module:unload()
      if modules.client_modulemanager then
        ClientModuleManager.updateModuleInfo(module:getName())
        ClientModuleManager.refreshLoadedModules()
      end
    end
  end
end

function ClientModuleManager.reloadAllModules()
  g_modules.reloadModules()
  ClientModuleManager.refreshLoadedModules()
  ClientModuleManager.show()
end

