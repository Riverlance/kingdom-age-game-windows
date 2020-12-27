_G.GameBlinkHit = { }



local blinkTime = 250
local events    = {}

local function removeBlink(id)
  local creature = g_map.getCreatureById(id)
  if creature and creature:getBlinkHitEffect() then
    creature:setBlinkHitEffect(false)
  end

  removeEvent(events[id])
  events[id] = nil
end



function GameBlinkHit.init()
  -- Alias
  GameBlinkHit.m = modules.ka_game_blinkhit

  GameBlinkHit.removeAll(true)
  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeBlinkHit, GameBlinkHit.onBlinkHit)
end

function GameBlinkHit.terminate()
  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeBlinkHit)
  GameBlinkHit.removeAll(true)
end

function GameBlinkHit.remove(id, instantly)
  if instantly then
    removeBlink(id)
    return
  end

  removeEvent(events[id])
  events[id] = scheduleEvent(function() removeBlink(id) end, blinkTime)
end

function GameBlinkHit.removeAll(instantly)
  for id, _ in ipairs(events) do
    GameBlinkHit.remove(id, instantly)
  end
  if instantly then
    events = {}
  end
end

function GameBlinkHit.add(id)
  local creature = g_map.getCreatureById(id)
  if not creature then
    return
  end

  -- Will keep enabled if another event is added before the last finishes
  if creature:getBlinkHitEffect() and events[id] then
    removeEvent(events[id])
  end
  creature:setBlinkHitEffect(true)

  GameBlinkHit.remove(id)
end

function GameBlinkHit.onBlinkHit(protocolGame, opcode, msg)
  local buffer = msg:getString()

  local id = tonumber(buffer)
  if not id then
    return
  end

  GameBlinkHit.add(id)
end
