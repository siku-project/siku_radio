RadioRooms = {}

local EVENT_ROOM <const> = 'siku_radio:client:setRoom'
local EVENT_MEMBERS <const> = 'siku_radio:client:setMembers'
local EVENT_TALKING <const> = 'siku_radio:client:setTalking'
local EVENT_ALERT <const> = 'siku_radio:client:alert'
local EVENT_ALERT_SENT <const> = 'siku_radio:client:alertSent'
local EVENT_ALERT_REFUSED <const> = 'siku_radio:client:alertRefused'
local EVENT_REFUSED <const> = 'siku_radio:client:tuneRefused'
local LOCAL_EVENT_TUNED <const> = 'siku:radio:playerTuned'
local LOCAL_EVENT_ALERT <const> = 'siku:radio:alert'

local rooms <const> = {}
local sessions <const> = {}
local cooldowns <const> = {}

--- Whether a session is online.
---@param sessionId any The player server id.
---@return boolean online Whether the player is connected.
local function isOnline(sessionId)
  return type(sessionId) == 'number' and GetPlayerName(tostring(sessionId)) ~= nil
end

--- The members of a room as the clients need them.
---@param key string The room key.
---@return table members A list of { id, name }.
local function describeMembers(key)
  local list <const> = {}

  for sessionId in pairs(rooms[key] or {}) do
    list[#list + 1] = { id = sessionId, name = GetPlayerName(tostring(sessionId)) or ('#' .. sessionId) }
  end

  table.sort(list, function(a, b)
    return a.id < b.id
  end)

  return list
end

--- Tells every member of a room who is in it.
---@param key string The room key.
---@return nil
local function broadcastMembers(key)
  local members <const> = describeMembers(key)

  for sessionId in pairs(rooms[key] or {}) do
    TriggerClientEvent(EVENT_MEMBERS, sessionId, key, members)
  end
end

--- Takes a player out of the room they are in, quietly.
---@param sessionId number The player server id.
---@return string? key The room they left, or nil.
local function detach(sessionId)
  local session <const> = sessions[sessionId]

  if not session then
    return nil
  end

  sessions[sessionId] = nil

  local room <const> = rooms[session.key]

  if room then
    if session.talking then
      for member in pairs(room) do
        if member ~= sessionId then
          TriggerClientEvent(EVENT_TALKING, member, sessionId, false)
        end
      end
    end

    room[sessionId] = nil

    if not next(room) then
      rooms[session.key] = nil
    end
  end

  return session.key
end

--- Puts a player on a frequency and channel, after the checks. Refusals
--- are told to the client with a reason.
---@param sessionId number The player server id.
---@param rawFrequency any The frequency asked for.
---@param rawChannel any The channel asked for, 1 when omitted.
---@return boolean tuned Whether the player is now on it.
function RadioRooms.tune(sessionId, rawFrequency, rawChannel)
  if not isOnline(sessionId) then
    return false
  end

  local frequency <const> = RadioBands.normalize(rawFrequency)
  local channel <const> = rawChannel == nil and 1 or rawChannel

  if not frequency or not RadioBands.hasChannel(frequency, channel) then
    TriggerClientEvent(EVENT_REFUSED, sessionId, 'invalid')
    return false
  end

  if not RadioAccess.canTune(sessionId, frequency) or not RadioItem.verify(sessionId) then
    TriggerClientEvent(EVENT_REFUSED, sessionId, RadioBands.reserved(frequency) and 'job' or 'access')
    return false
  end

  local key <const> = RadioBands.roomKey(frequency, channel)
  local previous <const> = detach(sessionId)

  rooms[key] = rooms[key] or {}
  rooms[key][sessionId] = true
  sessions[sessionId] = { key = key, frequency = frequency, channel = channel, talking = false }

  local band <const> = RadioBands.reserved(frequency)

  TriggerClientEvent(EVENT_ROOM, sessionId, {
    key = key,
    frequency = frequency,
    channel = channel,
    label = band and band.label or nil,
    channelLabel = RadioBands.channelLabel(frequency, channel),
    members = describeMembers(key),
  })

  if previous and previous ~= key then
    broadcastMembers(previous)
  end

  broadcastMembers(key)
  TriggerEvent(LOCAL_EVENT_TUNED, sessionId, frequency, channel)

  return true
end

--- Takes a player off the air.
---@param sessionId number The player server id.
---@return boolean left Whether they were on a frequency.
function RadioRooms.leave(sessionId)
  local key <const> = detach(sessionId)

  if not key then
    return false
  end

  if isOnline(sessionId) then
    TriggerClientEvent(EVENT_ROOM, sessionId, nil)
  end

  broadcastMembers(key)
  TriggerEvent(LOCAL_EVENT_TUNED, sessionId, nil, nil)

  return true
end

--- Marks a player as transmitting or not, and tells the other members.
---@param sessionId number The player server id.
---@param talking boolean Whether their key is held.
---@return nil
function RadioRooms.setTalking(sessionId, talking)
  local session <const> = sessions[sessionId]

  if not session or session.talking == talking then
    return
  end

  if talking and not RadioItem.verify(sessionId) then
    return
  end

  session.talking = talking

  for member in pairs(rooms[session.key] or {}) do
    if member ~= sessionId then
      TriggerClientEvent(EVENT_TALKING, member, sessionId, talking)
    end
  end
end

--- Everyone tuned to any band of a job, on any of its channels.
---@param job string The job name.
---@return table targets The server ids as keys.
local function jobAudience(job)
  local targets <const> = {}
  local bands <const> = RadioBands.list()

  for i = 1, #bands do
    if bands[i].job == job then
      local prefix <const> = ('%.3f/'):format(bands[i].frequency)

      for key, room in pairs(rooms) do
        if key:sub(1, #prefix) == prefix then
          for member in pairs(room) do
            targets[member] = true
          end
        end
      end
    end
  end

  return targets
end

--- Raises an emergency alert from a player of an emergency service to
--- everyone tuned to a band of that service, whatever the channel. The
--- receiving devices ring until their owner presses STOP.
---@param sessionId number The player server id.
---@return boolean sent Whether the alert went out.
function RadioRooms.alert(sessionId)
  if not AlertConfig.enabled then
    TriggerClientEvent(EVENT_ALERT_REFUSED, sessionId, 'disabled')
    return false
  end

  local session <const> = sessions[sessionId]

  if not session then
    TriggerClientEvent(EVENT_ALERT_REFUSED, sessionId, 'untuned')
    return false
  end

  local job <const> = RadioJobs.get(sessionId)

  if not job or not RadioBands.reserved(session.frequency) or RadioBands.reserved(session.frequency).job ~= job then
    TriggerClientEvent(EVENT_ALERT_REFUSED, sessionId, 'job')
    return false
  end

  local now <const> = os.time()

  if cooldowns[sessionId] and now - cooldowns[sessionId] < AlertConfig.cooldown then
    TriggerClientEvent(EVENT_ALERT_REFUSED, sessionId, 'cooldown')
    return false
  end

  cooldowns[sessionId] = now

  local band <const> = RadioBands.reserved(session.frequency)
  local alert <const> = {
    from = GetPlayerName(tostring(sessionId)) or ('#' .. sessionId),
    job = job,
    label = band.label,
    frequency = session.frequency,
    channel = session.channel,
    channelLabel = RadioBands.channelLabel(session.frequency, session.channel),
    at = now,
  }

  for member in pairs(jobAudience(job)) do
    if member ~= sessionId then
      TriggerClientEvent(EVENT_ALERT, member, alert)
    end
  end

  TriggerClientEvent(EVENT_ALERT_SENT, sessionId, alert)
  TriggerEvent(LOCAL_EVENT_ALERT, sessionId, session.frequency, session.channel)

  return true
end

--- Where a player is tuned.
---@param sessionId number The player server id.
---@return table? radio { frequency, channel, key, talking }, or nil when off the air.
function RadioRooms.get(sessionId)
  local session <const> = sessions[sessionId]

  if not session then
    return nil
  end

  return { frequency = session.frequency, channel = session.channel, key = session.key, talking = session.talking }
end

--- The players on a frequency and channel.
---@param frequency number The frequency.
---@param channel? number The channel, 1 when omitted.
---@return table members The server ids.
function RadioRooms.members(frequency, channel)
  local normalized <const> = RadioBands.normalize(frequency)
  local list <const> = {}

  if not normalized then
    return list
  end

  for sessionId in pairs(rooms[RadioBands.roomKey(normalized, channel or 1)] or {}) do
    list[#list + 1] = sessionId
  end

  return list
end

RegisterNetEvent('siku_radio:server:tune', function(frequency, channel)
  RadioRooms.tune(source, frequency, channel)
end)

RegisterNetEvent('siku_radio:server:leave', function()
  RadioRooms.leave(source)
end)

RegisterNetEvent('siku_radio:server:talking', function(talking)
  RadioRooms.setTalking(source, talking == true)
end)

RegisterNetEvent('siku_radio:server:alert', function()
  RadioRooms.alert(source)
end)

AddEventHandler('playerDropped', function()
  RadioRooms.leave(source)
  cooldowns[source] = nil
end)
