RadioVoice = {}

local VOICE_RESOURCE <const> = 'siku_voice'
local ROUTE <const> = 'radio'
local LAYER <const> = 'radio'
local HOLD_OWNER <const> = 'radio'
local SCOPE <const> = 'radio'
local STARTED <const> = 'started'

--- Whether the voice resource runs.
---@return boolean available Whether siku_voice answers.
local function hasVoice()
  return GetResourceState(VOICE_RESOURCE) == STARTED
end

--- Calls a voice export, swallowing a missing resource.
---@param name string The export name.
---@param ... any The arguments.
---@return any result What the export returned, or nil.
local function voice(name, ...)
  if not hasVoice() then
    return nil
  end

  local ok <const>, result <const> = pcall(function(...)
    return exports[VOICE_RESOURCE][name](nil, ...)
  end, ...)

  if not ok then
    Siku.print.warn(T('voice_export_failed', name, tostring(result)))
    return nil
  end

  return result
end

--- The rendering volume, 0 to 1, from the device volume.
---@return number volume The volume handed to the voice.
local function renderingVolume()
  return RadioState.volume() / 100
end

--- Whether the player may transmit right now: a radio in hand, on a
--- frequency, connected, and not closed by a restriction such as death or cuffs.
---@return boolean allowed Whether a transmission may start.
function RadioVoice.canTransmit()
  if not RadioState.hasDevice() or not RadioState.room() or not RadioState.isAllowed() then
    return false
  end

  if voice('IsConnected') ~= true then
    return false
  end

  return voice('IsRestricted', SCOPE) ~= true
end

--- Points the radio route at the other members of the room. The route
--- stays disabled until the key is held.
---@return nil
function RadioVoice.syncMembers()
  if not RadioState.room() then
    RadioVoice.clear()
    return
  end

  voice('SetRoute', ROUTE, { players = RadioState.memberIds() })
  voice('EnableRoute', ROUTE, RadioState.isTalking())
end

--- Opens the transmission: the route carries the voice, the microphone is
--- held open, the server tells the members.
---@return nil
function RadioVoice.startTransmit()
  voice('EnableRoute', ROUTE, true)
  voice('HoldTalk', HOLD_OWNER)
  TriggerServerEvent('siku_radio:server:talking', true)
end

--- Closes the transmission.
---@return nil
function RadioVoice.stopTransmit()
  voice('ReleaseTalk', HOLD_OWNER)
  voice('EnableRoute', ROUTE, false)
  TriggerServerEvent('siku_radio:server:talking', false)
end

--- Renders a member through the radio effect while they transmit, at the
--- device volume, or hands them back to proximity.
---@param id number The member server id.
---@param transmitting boolean Whether they transmit.
---@return nil
function RadioVoice.setReceiving(id, transmitting)
  if transmitting then
    voice('SetRendering', id, LAYER, {
      volume = renderingVolume(),
      effect = DeviceConfig.voice.effect,
      priority = DeviceConfig.voice.priority,
    })
  else
    voice('ClearRendering', id, LAYER)
  end
end

--- Applies the device volume to everyone transmitting right now.
---@return nil
function RadioVoice.applyVolume()
  for id in pairs(RadioState.receiving()) do
    RadioVoice.setReceiving(id, true)
  end
end

--- Drops the route and every radio layer, when the device leaves the air.
---@return nil
function RadioVoice.clear()
  voice('ClearRoute', ROUTE)
  voice('ClearRenderingLayer', LAYER)
end
