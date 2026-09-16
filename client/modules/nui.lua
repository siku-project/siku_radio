RadioNui = {}

local NUI_READY <const> = 'siku_radio:nui:ready'
local ACTION_LOCALE <const> = 'siku_radio:nui:setLocale'
local ACTION_CONFIG <const> = 'siku_radio:nui:setConfig'
local ACTION_STATE <const> = 'siku_radio:nui:setState'
local ACTION_VISIBLE <const> = 'siku_radio:nui:setVisible'
local ACTION_EVENT <const> = 'siku_radio:nui:event'

--- What the interface needs to know about the server's choices: the
--- access rule of this player, the frequencies, and the device settings.
---@return table config { access, frequencies, device }.
local function describeConfig()
  return {
    access = RadioState.access(),
    frequencies = RadioBands.describe(),
    device = {
      volume = DeviceConfig.volume,
      sounds = DeviceConfig.sounds,
      boot = DeviceConfig.boot,
      display = DeviceConfig.display,
      scan = DeviceConfig.scan,
    },
    alerts = { enabled = AlertConfig.enabled, autoStop = AlertConfig.autoStop },
  }
end

--- Sends the interface the language and its strings.
---@return nil
function RadioNui.pushLocale()
  SendNUIMessage({ action = ACTION_LOCALE, locale = RadioLocale.describe() })
end

--- Sends the interface the configuration, after it changed.
---@return nil
function RadioNui.pushConfig()
  SendNUIMessage({ action = ACTION_CONFIG, payload = describeConfig() })
end

--- Sends the interface a part of the device state.
---@param patch table The fields that changed.
---@return nil
function RadioNui.pushState(patch)
  SendNUIMessage({ action = ACTION_STATE, payload = patch })
end

--- Sends the interface the whole device state.
---@return nil
function RadioNui.pushAll()
  RadioNui.pushState(RadioState.describe())
end

--- Shows or hides the interface.
---@param visible boolean Whether the device is on screen.
---@return nil
function RadioNui.setVisible(visible)
  SendNUIMessage({ action = ACTION_VISIBLE, payload = { visible = visible == true } })
end

--- Tells the interface something happened: a refused tune, an alert.
---@param name string The event name.
---@param data? table What goes with it.
---@return nil
function RadioNui.pushEvent(name, data)
  SendNUIMessage({ action = ACTION_EVENT, payload = { name = name, data = data } })
end

RegisterNUICallback(NUI_READY, function(_, cb)
  cb({
    locale = RadioLocale.describe(),
    config = describeConfig(),
    state = RadioState.describe(),
    visible = RadioState.isOpen(),
  })
end)
