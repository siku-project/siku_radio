RadioState = {}

local access = { mode = AccessConfig.mode, allowed = false, job = nil, presets = {} }
local room = nil
local members = {}
local receiving = {}
local open = false
local talking = false
local volume = DeviceConfig.volume.default

--- The access rule as the server last sent it.
---@return table access { mode, allowed, job, presets }.
function RadioState.access()
  return access
end

--- Keeps the access rule the server sent.
---@param rule table { mode, allowed, job, presets }.
---@return nil
function RadioState.setAccess(rule)
  access = {
    mode = rule.mode,
    allowed = rule.allowed == true,
    job = rule.job,
    presets = type(rule.presets) == 'table' and rule.presets or {},
  }
end

--- Whether the player may use a radio.
---@return boolean allowed Whether the server allowed it.
function RadioState.isAllowed()
  return access.allowed
end

--- Where the device is tuned.
---@return table? room { key, frequency, channel, label?, channelLabel? }, or nil when off the air.
function RadioState.room()
  return room
end

--- Keeps the room the server put the player in, or none.
---@param value table? The room, or nil.
---@return nil
function RadioState.setRoom(value)
  if type(value) == 'table' then
    room = {
      key = value.key,
      frequency = value.frequency,
      channel = value.channel,
      label = value.label,
      channelLabel = value.channelLabel,
    }
    RadioState.setMembers(value.members)
  else
    room = nil
    RadioState.setMembers({})
  end
end

--- The players sharing the room.
---@return table members A list of { id, name }.
function RadioState.members()
  return members
end

--- The server ids of the other members.
---@return table ids A list of server ids.
function RadioState.memberIds()
  local ids <const> = {}
  local self <const> = GetPlayerServerId(PlayerId())

  for i = 1, #members do
    if members[i].id ~= self then
      ids[#ids + 1] = members[i].id
    end
  end

  return ids
end

--- Keeps the members the server listed.
---@param list any A list of { id, name }.
---@return nil
function RadioState.setMembers(list)
  members = type(list) == 'table' and list or {}

  local present <const> = {}

  for i = 1, #members do
    present[members[i].id] = true
  end

  for id in pairs(receiving) do
    if not present[id] then
      receiving[id] = nil
    end
  end
end

--- Marks a member as transmitting or not.
---@param id number The member server id.
---@param value boolean Whether they transmit.
---@return nil
function RadioState.setReceiving(id, value)
  receiving[id] = value and true or nil
end

--- The members transmitting right now.
---@return table ids The server ids as keys.
function RadioState.receiving()
  return receiving
end

--- Whether anyone is transmitting to the player.
---@return boolean receiving Whether a member talks.
function RadioState.isReceiving()
  return next(receiving) ~= nil
end

--- Whether the device is shown.
---@return boolean open Whether the interface is on screen.
function RadioState.isOpen()
  return open
end

--- Keeps whether the device is shown.
---@param value boolean Whether the interface is on screen.
---@return nil
function RadioState.setOpen(value)
  open = value == true
end

--- Whether the player holds the talk key.
---@return boolean talking Whether a transmission is running.
function RadioState.isTalking()
  return talking
end

--- Keeps whether the player transmits.
---@param value boolean Whether the key is held.
---@return nil
function RadioState.setTalking(value)
  talking = value == true
end

--- The device volume, 0 to 100.
---@return number volume The volume.
function RadioState.volume()
  return volume
end

--- Keeps the device volume.
---@param value any The volume, 0 to 100.
---@return boolean applied Whether the value was usable.
function RadioState.setVolume(value)
  if type(value) ~= 'number' or value ~= value then
    return false
  end

  volume = math.max(0, math.min(100, math.floor(value + 0.5)))

  return true
end

--- The whole device state as the interface needs it. Who else is on the
--- frequency stays on the game side.
---@return table state { tuned, transmitting, receiving, volume }.
function RadioState.describe()
  return {
    tuned = room,
    transmitting = talking,
    receiving = RadioState.isReceiving(),
    volume = volume,
  }
end
