RadioItem = {}

local MODE_ITEM <const> = 'item'
local STATE_STARTED <const> = 'started'
local VOLUME_DEBOUNCE_MS <const> = 400
local INVENTORY_STATE_EVENT <const> = 'siku_inventory:client:setState'
local CLOSE_POLL_MS <const> = 50
local CLOSE_TRIES <const> = 20

--- Whether the inventory screen is still up.
---@return boolean open Whether it holds the pointer.
local function isInventoryOpen()
  if GetResourceState(InventoryConfig.resource) ~= STATE_STARTED then
    return false
  end

  return exports[InventoryConfig.resource]:IsInventoryOpen() == true
end

local volumeTimer = nil

--- Whether radios come from the inventory.
---@return boolean enabled Whether the item mode is configured.
function RadioItem.isEnabled()
  return InventoryConfig.mode == MODE_ITEM
end

--- Whether the radio taken in hand is still in the bag, as the inventory
--- last told this client.
---@return boolean carried Whether the item is there.
local function isStillCarried()
  local uid <const> = RadioState.device().active

  if not uid or GetResourceState(InventoryConfig.resource) ~= STATE_STARTED then
    return true
  end

  local answer <const> = exports[InventoryConfig.resource]:GetItemSlots(InventoryConfig.item)

  for _, slot in ipairs(type(answer) == 'table' and answer.slots or {}) do
    if slot.uid == uid then
      return true
    end
  end

  return false
end

--- Tells the held radio its volume, a moment after the last change so a
--- long press writes once.
---@return nil
function RadioItem.reportVolume()
  if not RadioItem.isEnabled() or not RadioState.hasDevice() then
    return
  end

  if volumeTimer then
    return
  end

  volumeTimer = true

  SetTimeout(VOLUME_DEBOUNCE_MS, function()
    volumeTimer = nil
    TriggerServerEvent('siku_radio:server:volume', RadioState.volume())
  end)
end

RegisterNetEvent('siku_radio:client:setDevice', function(device)
  if type(device) ~= 'table' then
    return
  end

  RadioState.setDevice(device)

  if type(device.volume) == 'number' and RadioState.setVolume(device.volume) then
    RadioVoice.applyVolume()
    RadioNui.pushState({ volume = RadioState.volume() })
  end

  if not RadioState.hasDevice() then
    RadioTalk.stop()
    RadioUi.close()
  end
end)

RegisterNetEvent('siku_radio:client:deviceTaken', function()
  CreateThread(function()
    for _ = 1, CLOSE_TRIES do
      if not isInventoryOpen() then
        break
      end

      Wait(CLOSE_POLL_MS)
    end

    RadioUi.open()
  end)
end)

RegisterNetEvent(INVENTORY_STATE_EVENT, function()
  if RadioItem.isEnabled() and not isStillCarried() then
    TriggerServerEvent('siku_radio:server:checkDevice')
  end
end)
