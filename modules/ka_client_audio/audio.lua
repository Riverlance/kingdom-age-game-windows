_G.ClientAudio = { }



local ACTION_CHANNEL_PLAY                 = 0
local ACTION_CHANNEL_STOP                 = 1
local ACTION_CHANNEL_SETCHANNELAUDIOSGAIN = 2
local ACTION_CHANNEL_SETGAIN              = 3
local ACTION_CHANNEL_STOPAUDIOS           = 4
local ACTION_CHANNEL_AUDIOSSETGAIN        = 5

local channels = {}
for channelId = AudioChannels.First, AudioChannels.Last do
  channels[channelId] = {}
  channels[channelId].id      = channelId -- Same as its key
  channels[channelId].volume  = 0
  channels[channelId].channel = g_sounds.getChannel(channelId)
end

local function setChannelVolume(channelId, volume)
  if not channels[channelId] then
    return
  end

  channels[channelId].volume = volume
  channels[channelId].channel:setGain(volume)
end



function ClientAudio.init()
  -- Alias
  ClientAudio.m = modules.ka_client_audio

  local isAudioEnabled = ClientOptions.getOption('enableAudio')

  channels[AudioChannels.Music].volume   = isAudioEnabled and ClientOptions.getOption('enableMusic') and ClientOptions.getOption('musicVolume') or 0
  channels[AudioChannels.Ambient].volume = isAudioEnabled and ClientOptions.getOption('enableSoundAmbient') and ClientOptions.getOption('soundAmbientVolume') or 0
  channels[AudioChannels.Effect].volume  = isAudioEnabled and ClientOptions.getOption('enableSoundEffect') and ClientOptions.getOption('soundEffectVolume') or 0

  ProtocolGame.registerExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeAudio, ClientAudio.parseAudioRequest)

  connect(LocalPlayer, {
    onPositionChange = ClientAudio.onPositionChange
  })
end

function ClientAudio.terminate()
  disconnect(LocalPlayer, {
    onPositionChange = ClientAudio.onPositionChange
  })

  ProtocolGame.unregisterExtendedOpcode(ServerExtOpcodes.ServerExtOpcodeAudio)

  ClientAudio.clearAudios()

  _G.ClientAudio = nil
end

function ClientAudio.onPositionChange(creature, newPos, oldPos)
  ClientAudio.updateAudios()
end

function ClientAudio.setMusicVolume(volume)
  setChannelVolume(AudioChannels.Music, volume)
end
function ClientAudio.setAmbientVolume(volume)
  setChannelVolume(AudioChannels.Ambient, volume)
end
function ClientAudio.setEffectVolume(volume)
  setChannelVolume(AudioChannels.Effect, volume)
end

function ClientAudio.updateAudios()
  if not g_game.isOnline() then
    return
  end

  local position = g_game.getLocalPlayer():getPosition()
  for channelId, _channel in ipairs(channels) do
    local channel = _channel.channel
    if channel then
      channel:setThingPosition(position.x, position.y)
    end
  end
end

function ClientAudio.clearAudios()
  g_sounds.stopAll()
  for channelId, _channel in ipairs(channels) do
    local channel = _channel.channel
    if channel then
      channel:clear()
    end
  end
end

function ClientAudio.getRootPath()
  return '/audios/'
end

function ClientAudio.parseAudioRequest(protocolGame, opcode, msg)
  local buffer = msg:getString()
  local params = string.split(buffer, ':')

  local action = tonumber(params[1])
  if not action then
    return
  end

  if action == ACTION_CHANNEL_PLAY then
    local channelId = tonumber(params[2])
    local path = params[3]
    local gain = tonumber(params[4])
    local repetitions = tonumber(params[5])
    local fadeInTime = tonumber(params[6])
    local x = tonumber(params[7])
    local y = tonumber(params[8])
    if not channelId or path == '' or not gain or not repetitions or not fadeInTime or not x or not y then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    path = string.format('%s%s', ClientAudio.getRootPath(), path)
    local audio = channel:play(path, gain, repetitions, fadeInTime)
    if audio and x ~= 0 and y ~= 0 then
      audio:setPosition(x, y)
    end

  elseif action == ACTION_CHANNEL_STOP then
    local channelId = tonumber(params[2])
    local fadeOutTime = tonumber(params[3])
    if not channelId or not fadeOutTime then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    channel:stop(fadeOutTime)

  elseif action == ACTION_CHANNEL_SETCHANNELAUDIOSGAIN then
    local channelId = tonumber(params[2])
    local gain = tonumber(params[3])
    if not channelId or not gain then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    channel:setAudioGroupGain(gain)

  elseif action == ACTION_CHANNEL_SETGAIN then
    local channelId = tonumber(params[2])
    local gain = tonumber(params[3])
    if not channelId or not gain then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    channel:setGain(gain)

  elseif action == ACTION_CHANNEL_STOPAUDIOS then
    local channelId = tonumber(params[2])
    local path = params[3]
    local fadeOutTime = tonumber(params[4])
    if not channelId or path == '' or not fadeOutTime then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    path = string.format('%s%s', ClientAudio.getRootPath(), path)
    channel:stopAudioGroup(path, fadeOutTime)

 elseif action == ACTION_CHANNEL_AUDIOSSETGAIN then
    local channelId = tonumber(params[2])
    local path = params[3]
    local gain = tonumber(params[4])
    if not channelId or path == '' or not gain then
      return
    end

    local channel = channels[channelId].channel
    if not channel then
      return
    end

    path = string.format('%s%s', ClientAudio.getRootPath(), path)
    channel:setAudioGroupGain(path, gain)
  end
end
