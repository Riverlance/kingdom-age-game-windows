_G.GameSkills = { }



skillsWindow = nil
skillsTopMenuButton = nil

contentsPanel = nil

function GameSkills.init()
  -- Alias
  GameSkills.m = modules.game_skills

  connect(LocalPlayer, {
    onExperienceChange      = GameSkills.onExperienceChange,
    onLevelChange           = GameSkills.onLevelChange,
    onStaminaChange         = GameSkills.onStaminaChange,
    onRegenerationChange    = GameSkills.onRegenerationChange,
    onSpeedChange           = GameSkills.onSpeedChange,
    onBaseSpeedChange       = GameSkills.onBaseSpeedChange,
  })
  connect(g_game, {
    onGameStart = GameSkills.online,
    onGameEnd   = GameSkills.offline
  })

  skillsWindow = g_ui.loadUI('skills')
  skillsTopMenuButton = ClientTopMenu.addRightGameToggleButton('skillsTopMenuButton', tr('Stats') .. ' (Ctrl+T)', '/images/ui/top_menu/skills', GameSkills.toggle)

  skillsWindow.topMenuButton = skillsTopMenuButton

  contentsPanel = skillsWindow:getChildById('contentsPanel')

  g_keyboard.bindKeyDown('Ctrl+T', GameSkills.toggle)

  GameInterface.setupMiniWindow(skillsWindow, skillsTopMenuButton)

  if g_game.isOnline() then
    GameSkills.online()
  end
end

function GameSkills.terminate()
  GameSkills.setupRegeneration(0)

  disconnect(LocalPlayer, {
    onExperienceChange      = GameSkills.onExperienceChange,
    onLevelChange           = GameSkills.onLevelChange,
    onStaminaChange         = GameSkills.onStaminaChange,
    onRegenerationChange    = GameSkills.onRegenerationChange,
    onSpeedChange           = GameSkills.onSpeedChange,
    onBaseSpeedChange       = GameSkills.onBaseSpeedChange,
  })
  disconnect(g_game, {
    onGameStart = GameSkills.online,
    onGameEnd   = GameSkills.offline
  })

  g_keyboard.unbindKeyDown('Ctrl+T')
  skillsTopMenuButton:destroy()
  skillsWindow:destroy()

  contentsPanel = nil
  skillsTopMenuButton = nil
  skillsWindow = nil

  _G.GameSkills = nil
end

function GameSkills.resetSkillColor(id)
  local skill = contentsPanel:getChildById(id)
  local widget = skill:getChildById('value')
  widget:setColor('#bbbbbb')
end

function GameSkills.toggleSkill(id, state)
  local skill = contentsPanel:getChildById(id)
  skill:setVisible(state)
end

function GameSkills.setSkillBase(id, value, baseValue)
  if baseValue <= 0 or value < 0 then
    return
  end
  local skill = contentsPanel:getChildById(id)
  local widget = skill:getChildById('value')

  if value > baseValue then
    widget:setColor('#008b00') -- green
    skill:setTooltip(baseValue .. ' +' .. (value - baseValue))
  elseif value < baseValue then
    widget:setColor('#b22222') -- red
    skill:setTooltip(baseValue .. ' ' .. (value - baseValue))
  else
    widget:setColor('#bbbbbb') -- default
    skill:removeTooltip()
  end
end

function GameSkills.setSkillValue(id, value)
  local skill = contentsPanel:getChildById(id)
  local widget = skill:getChildById('value')
  widget:setText(value)
end

function GameSkills.setSkillColor(id, value)
  local skill = contentsPanel:getChildById(id)
  local widget = skill:getChildById('value')
  widget:setColor(value)
end

function GameSkills.setSkillTooltip(id, value)
  local skill = contentsPanel:getChildById(id)
  local widget = skill:getChildById('value')
  widget:setTooltip(value)
end

function GameSkills.setSkillPercent(id, percent, tooltip)
  local skill = contentsPanel:getChildById(id)
  local widget = skill:getChildById('percent')
  if widget then
    widget:setPercent(math.floor(percent))

    if tooltip then
      widget:setTooltip(tooltip)
    end
  end
end

function GameSkills.checkAlert(id, value, maxValue, threshold, greaterThan)
  if greaterThan == nil then
    greaterThan = false
  end

  local alert = false

  -- maxValue can be set to false to check value and threshold
  -- used for regeneration checking
  if type(maxValue) == 'boolean' then
    if maxValue then
      return
    end

    if greaterThan then
      if value > threshold then
        alert = true
      end
    else
      if value < threshold then
        alert = true
      end
    end
  elseif type(maxValue) == 'number' then
    if maxValue < 0 then
      return
    end

    local percent = math.floor((value / maxValue) * 100)
    if greaterThan then
      if percent > threshold then
        alert = true
      end
    else
      if percent < threshold then
        alert = true
      end
    end
  end

  if alert then
    GameSkills.setSkillColor(id, '#b22222') -- red
  else
    GameSkills.resetSkillColor(id)
  end
end

function GameSkills.update()
  local regenerationTime = contentsPanel:getChildById('regenerationTime')
  if not g_game.getFeature(GamePlayerRegenerationTime) then
    regenerationTime:hide()
  else
    regenerationTime:show()
  end
end

function GameSkills.online()
  GameInterface.setupMiniWindow(skillsWindow, skillsTopMenuButton)

  local player = g_game.getLocalPlayer()

  if expSpeedEvent then
    expSpeedEvent:cancel()
  end

  expSpeedEvent = cycleEvent(GameSkills.checkExpSpeed, 30*1000)

  GameSkills.onExperienceChange(player, player:getExperience())
  GameSkills.onLevelChange(player, player:getLevel(), player:getLevelPercent())
  GameSkills.onStaminaChange(player, player:getStamina())
  GameSkills.onRegenerationChange(player, player:getRegenerationTime())
  GameSkills.onSpeedChange(player, player:getSpeed())

  GameSkills.update()
end

function GameSkills.offline()
  if expSpeedEvent then
    expSpeedEvent:cancel() expSpeedEvent = nil
  end

  GameSkills.setupRegeneration(0)
end

function GameSkills.toggle()
  GameInterface.toggleMiniWindow(skillsWindow)
end

function GameSkills.checkExpSpeed()
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  local currentExp = player:getExperience()
  local currentTime = g_clock.seconds()
  if player.lastExps ~= nil then
    player.expSpeed = (currentExp - player.lastExps[1][1])/(currentTime - player.lastExps[1][2])
    GameSkills.onLevelChange(player, player:getLevel(), player:getLevelPercent())
  else
    player.lastExps = {}
  end
  table.insert(player.lastExps, {currentExp, currentTime})
  if #player.lastExps > 30 then
    table.remove(player.lastExps, 1)
  end
end

function GameSkills.onSkillButtonClick(button)
  local percentBar = button:getChildById('percent')
  if percentBar then
    percentBar:setVisible(not percentBar:isVisible())
    if percentBar:isVisible() then
      button:setHeight(21)
    else
      button:setHeight(21 - 6)
    end
  end
end

function GameSkills.onExperienceChange(localPlayer, value)
  GameSkills.setSkillValue('experience', value)
end

function GameSkills.onLevelChange(localPlayer, level, levelPercent, oldLevel, oldLevelPercent)
  GameSkills.setSkillValue('level', level)
  GameSkills.setSkillPercent('level', levelPercent, getExperienceTooltipText(localPlayer, level, levelPercent))
end

function GameSkills.onStaminaChange(localPlayer, stamina)
  local hours = math.floor(stamina / 60)
  local minutes = stamina % 60
  if minutes < 10 then
    minutes = '0' .. minutes
  end

  GameSkills.setSkillValue('stamina', hours .. ":" .. minutes)

  local percent = math.floor(100 * stamina / (42 * 60)) -- max is 42 hours
  local text    = tr('Remaining %s%% (%s hours and %s minutes)', percent, hours, minutes)
  if stamina <= 840 and stamina > 0 then -- red phase
    text = string.format("%s\n%s", text, tr("You are receiving only 50%% of experience\nand you may not receive loot from monsters"))
  elseif stamina == 0 then
    text = string.format("%s\n%s", text, tr("You may not receive experience and loot from monsters"))
  end
  GameSkills.setSkillPercent('stamina', percent, text)
end

local regenerationEvent       = nil
local regenerationTime        = 0
local elapsedRegenerationTime = 0
function GameSkills.setupRegeneration(time)
  if time <= 0 then
    removeEvent(regenerationEvent)
    regenerationEvent = nil

    if time < 0 then
      time = 0
    end
  end

  local minutes = math.floor(time / 60)
  local seconds = time % 60
  if seconds < 10 then
    seconds = '0' .. seconds
  end

  GameSkills.setSkillValue('regenerationTime', minutes .. ":" .. seconds)
  GameSkills.checkAlert('regenerationTime', time, false, 300)
end
function GameSkills.onRegenerationChange(localPlayer, time)
  if not g_game.getFeature(GamePlayerRegenerationTime) or time < 0 then
    return
  end

  regenerationTime        = time
  elapsedRegenerationTime = 0

  removeEvent(regenerationEvent)
  regenerationEvent = cycleEvent(function()
    GameSkills.setupRegeneration(regenerationTime - elapsedRegenerationTime)
    elapsedRegenerationTime = elapsedRegenerationTime + 1
  end, 1000)

  GameSkills.setupRegeneration(time)
end

function GameSkills.onSpeedChange(localPlayer, speed)
  GameSkills.setSkillValue('speed', speed * 2)

  GameSkills.onBaseSpeedChange(localPlayer, localPlayer:getBaseSpeed())
end

function GameSkills.onBaseSpeedChange(localPlayer, baseSpeed)
  GameSkills.setSkillBase('speed', localPlayer:getSpeed() * 2, baseSpeed * 2)
end
