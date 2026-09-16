--- Shows the device.
---@return nil
local function open()
  RadioUi.open()
end

--- Hides the device.
---@return nil
local function close()
  RadioUi.close()
end

--- Shows or hides the device.
---@return nil
local function toggle()
  RadioUi.toggle()
end

--- Whether the device is on screen.
---@return boolean open Whether the interface shows.
local function isOpen()
  return RadioState.isOpen()
end

--- Where the device is tuned.
---@return table? room { key, frequency, channel, label?, channelLabel? }, or nil.
local function getTuned()
  return RadioState.room()
end

--- Asks the server for a frequency and channel.
---@param frequency number The frequency in MHz.
---@param channel? number The channel, 1 when omitted.
---@return nil
local function tune(frequency, channel)
  TriggerServerEvent('siku_radio:server:tune', frequency, channel or 1)
end

--- Leaves the frequency.
---@return nil
local function leave()
  TriggerServerEvent('siku_radio:server:leave')
end

--- Whether the player transmits right now.
---@return boolean talking Whether the key is held.
local function isTalking()
  return RadioState.isTalking()
end

--- Starts a transmission, as the key does.
---@return boolean started Whether it opened.
local function startTalking()
  return RadioTalk.start()
end

--- Ends a transmission.
---@return nil
local function stopTalking()
  RadioTalk.stop()
end

--- The device volume, 0 to 100.
---@return number volume The volume.
local function getVolume()
  return RadioState.volume()
end

--- Sets the device volume.
---@param value number 0 to 100.
---@return boolean applied Whether the value was usable.
local function setVolume(value)
  if not RadioState.setVolume(value) then
    return false
  end

  RadioVoice.applyVolume()
  RadioNui.pushState({ volume = RadioState.volume() })

  return true
end

exports('Open', open)
exports('Close', close)
exports('Toggle', toggle)
exports('IsOpen', isOpen)
exports('GetTuned', getTuned)
exports('Tune', tune)
exports('Leave', leave)
exports('IsTalking', isTalking)
exports('StartTalking', startTalking)
exports('StopTalking', stopTalking)
exports('GetVolume', getVolume)
exports('SetVolume', setVolume)
