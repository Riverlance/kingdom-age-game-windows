_G.ClientLocales = { }



localesWindow = nil



local installedLocales
local currentLocale
local GAMELANGUAGE_EN      = 1
local GAMELANGUAGE_PT      = 2
local GAMELANGUAGE_ES      = 3
local GAMELANGUAGE_DE      = 4
local GAMELANGUAGE_PL      = 5
local GAMELANGUAGE_SV      = 6
local GAMELANGUAGE_FIRST   = GAMELANGUAGE_EN
local GAMELANGUAGE_LAST    = GAMELANGUAGE_SV
local GAMELANGUAGE_DEFAULT = GAMELANGUAGE_EN
local defaultLocaleName    = 'en'
local language =
{
  ['en'] = GAMELANGUAGE_EN,
  ['pt'] = GAMELANGUAGE_PT,
  ['es'] = GAMELANGUAGE_ES,
  ['de'] = GAMELANGUAGE_DE,
  ['pl'] = GAMELANGUAGE_PL,
  ['sv'] = GAMELANGUAGE_SV
}



function ClientLocales.sendLocale(localeName)
  local protocolGame = g_game.getProtocolGame()
  if not protocolGame then
    return false
  end

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeLocale)
  msg:addString(localeName)
  protocolGame:send(msg)

  local msg = OutputMessage.create()
  msg:addU8(ClientOpcodes.ClientOpcodeExtendedOpcode)
  msg:addU16(ClientExtOpcodes.ClientExtOpcodeGameLanguage)
  msg:addString(tostring(language[localeName] or GAMELANGUAGE_EN))
  protocolGame:send(msg)

  return true
end

function ClientLocales.createWindow()
  localesWindow = g_ui.displayUI('locales')
  localesWindow.onEscape = ClientLocales.destroyWindow
  local localesPanel = localesWindow:getChildById('localesPanel')
  local layout = localesPanel:getLayout()
  local spacing = layout:getCellSpacing()
  local size = layout:getCellSize()

  local count = 0
  for name,locale in pairs(installedLocales) do
    local widget = g_ui.createWidget('LocalesButton', localesPanel)
    widget:setImageSource('/images/ui/flags/' .. name .. '')
    widget:setText(locale.languageName)
    widget.onClick = function() ClientLocales.selectFirstLocale(name) end
    count = count + 1
  end

  count = math.max(1, math.min(count, 3))
  localesPanel:setWidth(size.width*count + spacing*(count-1))

  addEvent(function() localesWindow:raise() localesWindow:focus() end)
end

function ClientLocales.destroyWindow()
  if localesWindow then
    localesWindow:destroy()
    localesWindow = nil
  end
end

function ClientLocales.selectFirstLocale(name)
  ClientLocales.destroyWindow()
  if ClientLocales.setLocale(name) then
    g_modules.reloadModules()
  end
end

function ClientLocales.onGameStart()
  ClientLocales.sendLocale(currentLocale.name)
end

function ClientLocales.onExtendedLocales(protocolGame, opcode, msg)
  local buffer = msg:getString()

  local locale = installedLocales[buffer]
  if locale and ClientLocales.setLocale(locale.name) then
    g_modules.reloadModules()
  end
end

function ClientLocales.init()
  -- Alias
  ClientLocales.m = modules.client_locales

  installedLocales = {}

  ClientLocales.installLocales('/locales')

  local userLocaleName = g_settings.get('locale', 'false')
  if userLocaleName ~= 'false' and ClientLocales.setLocale(userLocaleName) then
    -- pdebug('Using configured locale: ' .. userLocaleName)
  else
    ClientLocales.setLocale(defaultLocaleName)
    connect(g_app, {
      onRun = ClientLocales.createWindow
    })
  end

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeLocale, ClientLocales.onExtendedLocales)
  connect(g_game, {
    onGameStart = ClientLocales.onGameStart
  })
end

function ClientLocales.terminate()
  installedLocales = nil
  currentLocale = nil

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeLocale)

  disconnect(g_app, {
    onRun = ClientLocales.createWindow
  })

  disconnect(g_game, {
    onGameStart = ClientLocales.onGameStart
  })

  _G.ClientLocales = nil
end

function ClientLocales.generateNewTranslationTable(localename)
  local locale = installedLocales[localename]
  for _i,k in pairs(neededTranslations) do
    local trans = locale.translation[k]
    k = k:gsub('\n','\\n')
    k = k:gsub('\t','\\t')
    k = k:gsub('\"','\\\"')
    if trans then
      trans = trans:gsub('\n','\\n')
      trans = trans:gsub('\t','\\t')
      trans = trans:gsub('\"','\\\"')
    end
    if not trans then
      print('    ["' .. k .. '"]' .. ' = false,')
    else
      print('    ["' .. k .. '"]' .. ' = "' .. trans .. '",')
    end
  end
end

function ClientLocales.installLocale(locale)
  if not locale or not locale.name then
    error('Unable to install locale.')
  end

  if _G.allowedLocales and not _G.allowedLocales[locale.name] then
    return
  end

  if locale.name ~= defaultLocaleName then
    local updatesNamesMissing = {}
    for _,k in pairs(neededTranslations) do
      if locale.translation[k] == nil then
        updatesNamesMissing[#updatesNamesMissing + 1] = k
      end
    end

    if #updatesNamesMissing > 0 then
      pdebug('Locale \'' .. locale.name .. '\' is missing ' .. #updatesNamesMissing .. ' translations.')
      for _,name in pairs(updatesNamesMissing) do
        pdebug('\t"' .. name ..'"')
      end
    end
  end

  local installedLocale = installedLocales[locale.name]
  if installedLocale then
    for word,translation in pairs(locale.translation) do
      installedLocale.translation[word] = translation
    end
  else
    installedLocales[locale.name] = locale
  end
end

function ClientLocales.installLocales(directory)
  dofiles(directory)
end

function ClientLocales.setLocale(name)
  local locale = installedLocales[name]
  if locale == currentLocale then
    g_settings.set('locale', name)
    return
  end
  if not locale then
    pwarning("Locale " .. name .. ' does not exist.')
    return false
  end
  if currentLocale then
    ClientLocales.sendLocale(locale.name)
  end
  currentLocale = locale
  g_settings.set('locale', name)
  if onLocaleChanged then
    onLocaleChanged(name)
  end

  return true
end

function ClientLocales.getInstalledLocales()
  return installedLocales
end

function ClientLocales.getCurrentLocale()
  return currentLocale
end



-- global function used to translate texts
function _G.tr(text, ...)
  if currentLocale then
    if tonumber(text) and currentLocale.formatNumbers then
      local number = tostring(text):split('.')
      local out = ''
      local reverseNumber = number[1]:reverse()
      for i=1,#reverseNumber do
        out = out .. reverseNumber:sub(i, i)
        if i % 3 == 0 and i ~= #number and i ~= #reverseNumber then
          out = out .. currentLocale.thousandsSeperator
        end
      end

      if number[2] then
        out = number[2] .. currentLocale.decimalSeperator .. out
      end
      return out:reverse()
    elseif tostring(text) then
      local translation = currentLocale.translation[text]
      if not translation then
        if translation == nil then
          if currentLocale.name ~= defaultLocaleName then
            if g_game.getAccountType() >= ACCOUNT_TYPE_GAMEMASTER then
              pdebug('Unable to translate: \"' .. text .. '\"')
            end
          end
        end
        translation = text
      end
      return string.format(translation, ...)
    end
  end
  return text
end
