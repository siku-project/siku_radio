RadioUi = {}

local KEYBIND <const> = 'siku_radio_open'

--- Reads a NUI callback argument as a number.
---@param value any The raw value.
---@return number? number The number, or nil.
local function toNumber(value)
  local number <const> = tonumber(value)

  if number == nil or number ~= number then
    return nil
  end

  return number
end

--- Shows the device and gives it the pointer, keeping the game keys so the
--- player still moves and still transmits.
---@return nil
function RadioUi.open()
  if RadioState.isOpen() then
    return
  end

  RadioState.setOpen(true)
  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(true)
  RadioNui.setVisible(true)
end

--- Hides the device. The frequency stays tuned: a closed radio still talks
--- and still listens.
---@return nil
function RadioUi.close()
  if not RadioState.isOpen() then
    return
  end

  RadioState.setOpen(false)
  SetNuiFocusKeepInput(false)
  SetNuiFocus(false, false)
  RadioNui.setVisible(false)
end

--- Shows or hides the device.
---@return nil
function RadioUi.toggle()
  if RadioState.isOpen() then
    RadioUi.close()
  else
    RadioUi.open()
  end
end

RegisterNUICallback('siku_radio:nui:close', function(_, cb)
  cb({})
  RadioUi.close()
end)

RegisterNUICallback('siku_radio:nui:tune', function(data, cb)
  cb({})

  local frequency <const> = toNumber(type(data) == 'table' and data.frequency or nil)
  local channel <const> = toNumber(type(data) == 'table' and data.channel or nil)

  if frequency then
    TriggerServerEvent('siku_radio:server:tune', frequency, channel and math.floor(channel) or 1)
  end
end)

RegisterNUICallback('siku_radio:nui:leave', function(_, cb)
  cb({})
  TriggerServerEvent('siku_radio:server:leave')
end)

RegisterNUICallback('siku_radio:nui:volume', function(data, cb)
  cb({})

  local value <const> = toNumber(type(data) == 'table' and data.value or nil)

  if value and RadioState.setVolume(value) then
    RadioVoice.applyVolume()
    RadioNui.pushState({ volume = RadioState.volume() })
  end
end)

RegisterNUICallback('siku_radio:nui:alert', function(_, cb)
  cb({})
  TriggerServerEvent('siku_radio:server:alert')
end)

RegisterNetEvent('siku_radio:client:toggle', function()
  RadioUi.toggle()
end)

RegisterNetEvent('siku_radio:client:setOpen', function(open)
  if open then
    RadioUi.open()
  else
    RadioUi.close()
  end
end)

if type(DeviceConfig.keybinds.open) == 'string' and DeviceConfig.keybinds.open ~= '' then
  Siku.keybind.add({
    name = KEYBIND,
    description = T('keybind_open'),
    defaultKey = DeviceConfig.keybinds.open,
    onPressed = function()
      RadioUi.toggle()
    end,
  })
end

AddEventHandler('onResourceStop', function(resource)
  if resource == Siku.name then
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
  end
end)
