--- Whether a session is online.
---@param sessionId any The player server id.
---@return boolean online Whether the player is connected.
local function isOnline(sessionId)
  return type(sessionId) == 'number' and GetPlayerName(tostring(sessionId)) ~= nil
end

--- Where a player is tuned, and what they may do.
---@param sessionId number The player server id.
---@return table? radio { frequency?, channel?, key?, talking, allowed, job }, or nil when offline.
local function getPlayerRadio(sessionId)
  if not isOnline(sessionId) then
    return nil
  end

  local room <const> = RadioRooms.get(sessionId) or {}

  return {
    frequency = room.frequency,
    channel = room.channel,
    key = room.key,
    talking = room.talking == true,
    allowed = RadioAccess.isAllowed(sessionId),
    job = RadioJobs.get(sessionId),
  }
end

--- Puts a player on a frequency, with the same checks as the device.
---@param sessionId number The player server id.
---@param frequency number The frequency in MHz.
---@param channel? number The channel, 1 when omitted.
---@return boolean tuned Whether the player is now on it.
local function tunePlayer(sessionId, frequency, channel)
  return RadioRooms.tune(sessionId, frequency, channel)
end

--- Takes a player off the air.
---@param sessionId number The player server id.
---@return boolean left Whether they were on a frequency.
local function untunePlayer(sessionId)
  return RadioRooms.leave(sessionId)
end

--- The players on a frequency and channel.
---@param frequency number The frequency in MHz.
---@param channel? number The channel, 1 when omitted.
---@return table members The server ids.
local function getMembers(frequency, channel)
  return RadioRooms.members(frequency, channel)
end

--- Opens or closes the device of a player.
---@param sessionId number The player server id.
---@param open boolean Whether the device shows.
---@return boolean sent Whether the request reached the client.
local function setPlayerRadioOpen(sessionId, open)
  if not isOnline(sessionId) then
    return false
  end

  TriggerClientEvent('siku_radio:client:setOpen', sessionId, open == true)

  return true
end

--- Lets a job resource decide the job of a player.
---@param resolver function? Receives the server id, returns the job name or nil.
---@return boolean applied Whether the resolver was stored.
local function setJobResolver(resolver)
  return RadioJobs.setResolver(resolver)
end

--- Sends every player their access rule again, after jobs changed.
---@return nil
local function refreshAccess()
  RadioAccess.pushAll()
end

exports('GetPlayerRadio', getPlayerRadio)
exports('TunePlayer', tunePlayer)
exports('UntunePlayer', untunePlayer)
exports('GetMembers', getMembers)
exports('SetPlayerRadioOpen', setPlayerRadioOpen)
exports('SetJobResolver', setJobResolver)
exports('RefreshAccess', refreshAccess)
