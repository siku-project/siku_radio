RadioItem = {}

local MODE_ITEM <const> = 'item'
local STATE_STARTED <const> = 'started'
local EVENT_DEVICE <const> = 'siku_radio:client:setDevice'
local EVENT_SET_OPEN <const> = 'siku_radio:client:setOpen'
local EVENT_TAKEN <const> = 'siku_radio:client:deviceTaken'
local LOCAL_EVENT_TUNED <const> = 'siku:radio:playerTuned'
local LOAD_POLL_MS <const> = 250
local LOAD_TRIES <const> = 20

local active <const> = {}
local registered = false

--- Whether radios come from the inventory at all.
---@return boolean enabled Whether the item mode is configured.
function RadioItem.isEnabled()
  return InventoryConfig.mode == MODE_ITEM
end

--- Whether the inventory resource runs right now.
---@return boolean running Whether its exports answer.
local function isInventoryRunning()
  return GetResourceState(InventoryConfig.resource) == STATE_STARTED
end

--- Calls an inventory export, or nothing when the inventory is away.
---@param name string The export name.
---@param ... any The arguments.
---@return any ... Whatever the export answers, nil when it could not be asked.
local function inventory(name, ...)
  if not isInventoryRunning() then
    return nil
  end

  local ok <const>, first, second = pcall(function(...)
    return exports[InventoryConfig.resource][name](nil, ...)
  end, ...)

  if not ok then
    Siku.print.warn(T('inventory_export_failed', name, tostring(first)))
    return nil
  end

  return first, second
end

--- The character id behind a session, the key the inventory works with.
---@param sessionId number The player server id.
---@return number? characterId The character id, or nil without a character.
local function characterOf(sessionId)
  local character <const> = Siku.cache.getCurrentCharacter(sessionId)

  if type(character) ~= 'table' or type(character.id) ~= 'number' then
    return nil
  end

  return character.id
end

--- The radio a session holds, as the inventory still sees it.
---@param sessionId number The player server id.
---@return table? instance { slot, item, uid, metadata, ... }, or nil when it is gone.
local function heldInstance(sessionId)
  local uid <const> = active[sessionId]
  local characterId <const> = characterOf(sessionId)

  if not uid or not characterId then
    return nil
  end

  return inventory('GetItemByUid', characterId, uid)
end

--- What a radio remembers, read from its metadata with safe defaults.
---@param metadata any The item metadata.
---@return table state { power, frequency?, channel, volume? }.
local function readState(metadata)
  local data <const> = type(metadata) == 'table' and metadata or {}

  return {
    power = data.power == true,
    frequency = type(data.frequency) == 'number' and data.frequency or nil,
    channel = type(data.channel) == 'number' and data.channel or 1,
    volume = type(data.volume) == 'number' and data.volume or nil,
  }
end

--- Writes a change into the metadata of the radio a session holds, keeping
--- whatever else the inventory stored on it.
---@param sessionId number The player server id.
---@param patch table The keys to set; a false value clears the key.
---@return boolean saved Whether the inventory took it.
local function save(sessionId, patch)
  local instance <const> = heldInstance(sessionId)

  if not instance then
    return false
  end

  local metadata <const> = type(instance.metadata) == 'table' and instance.metadata or {}

  for key, value in pairs(patch) do
    if value == false then
      metadata[key] = nil
    else
      metadata[key] = value
    end
  end

  local saved <const> = inventory('SetItemMetadata', characterOf(sessionId), instance.uid, metadata)

  return saved == true
end

--- Tells the client which radio it holds, and the volume it remembers.
---@param sessionId number The player server id.
---@param volume? number The volume to apply, when known.
---@return nil
local function pushDevice(sessionId, volume)
  TriggerClientEvent(EVENT_DEVICE, sessionId, {
    mode = InventoryConfig.mode,
    active = active[sessionId],
    volume = volume,
  })
end

--- Whether a session may act through a radio right now: always in command
--- mode, otherwise only while the radio it took in hand is still carried.
---@param sessionId number The player server id.
---@return boolean holds Whether a radio answers.
function RadioItem.holds(sessionId)
  if not RadioItem.isEnabled() then
    return true
  end

  return heldInstance(sessionId) ~= nil
end

--- The uid of the radio a session holds.
---@param sessionId number The player server id.
---@return string? uid The item instance id, or nil.
function RadioItem.active(sessionId)
  return active[sessionId]
end

--- Takes a radio in hand: it becomes the session's device, powers on, and
--- comes back where it was left. Nothing is consumed.
---@param sessionId number The player server id.
---@param uid string The item instance id.
---@param metadata any The item metadata.
---@param open boolean Whether the interface opens.
---@return nil
function RadioItem.take(sessionId, uid, metadata, open)
  local state <const> = readState(metadata)

  if active[sessionId] and active[sessionId] ~= uid then
    RadioRooms.leave(sessionId)
  end

  active[sessionId] = uid
  save(sessionId, { power = true })
  pushDevice(sessionId, state.volume)

  if state.frequency and not RadioRooms.tune(sessionId, state.frequency, state.channel) then
    save(sessionId, { frequency = false, channel = false })
  end

  if open then
    TriggerClientEvent(EVENT_TAKEN, sessionId)
  end
end

--- Puts the radio down: off the air, interface away, no device in hand.
---@param sessionId number The player server id.
---@return nil
function RadioItem.release(sessionId)
  if not active[sessionId] then
    return
  end

  RadioRooms.leave(sessionId)
  active[sessionId] = nil
  pushDevice(sessionId, nil)
  TriggerClientEvent(EVENT_SET_OPEN, sessionId, false)
end

--- Switches the held radio off: it remembers being off, and stays in the
--- pocket until used again.
---@param sessionId number The player server id.
---@return nil
function RadioItem.powerOff(sessionId)
  save(sessionId, { power = false })
  RadioItem.release(sessionId)
end

--- Checks that the held radio is still carried, and lets go of it otherwise.
---@param sessionId number The player server id.
---@return boolean holds Whether it is still there.
function RadioItem.verify(sessionId)
  if not RadioItem.isEnabled() or not active[sessionId] then
    return true
  end

  if heldInstance(sessionId) then
    return true
  end

  RadioItem.release(sessionId)

  return false
end

--- Puts a powered radio found in the pocket back on the air, when the
--- character loads.
---@param sessionId number The player server id.
---@return nil
local function restore(sessionId)
  for _ = 1, LOAD_TRIES do
    local characterId <const> = characterOf(sessionId)
    local answer <const> = characterId and inventory('GetItemSlots', characterId, InventoryConfig.item)

    if type(answer) == 'table' and type(answer.slots) == 'table' then
      for _, slot in ipairs(answer.slots) do
        if slot.uid and readState(slot.metadata).power then
          RadioItem.take(sessionId, slot.uid, slot.metadata, false)
          return
        end
      end

      return
    end

    Wait(LOAD_POLL_MS)
  end
end

--- Binds the item use to the radio, once the inventory runs.
---@return nil
local function register()
  if registered or not RadioItem.isEnabled() or not isInventoryRunning() then
    return
  end

  local bound <const> = inventory('RegisterItemUse', InventoryConfig.item, {
    canUse = function(sessionId)
      return RadioAccess.isAllowed(sessionId)
    end,
    onUse = function(sessionId, context)
      if type(context) ~= 'table' or type(context.uid) ~= 'string' then
        Siku.print.warn(T('inventory_item_not_unique', InventoryConfig.item))
        return
      end

      RadioItem.take(sessionId, context.uid, context.metadata, true)
    end,
  })

  registered = bound == true

  if registered then
    Siku.print.success(T('inventory_linked', InventoryConfig.item, InventoryConfig.resource))
  end
end

AddEventHandler(LOCAL_EVENT_TUNED, function(sessionId, frequency, channel)
  if not active[sessionId] then
    return
  end

  save(sessionId, { frequency = frequency or false, channel = channel or false })
end)

RegisterNetEvent('siku_radio:server:volume', function(volume)
  if type(volume) == 'number' and active[source] then
    save(source, { volume = math.max(0, math.min(100, math.floor(volume + 0.5))) })
  end
end)

RegisterNetEvent('siku_radio:server:power', function()
  RadioItem.powerOff(source)
end)

RegisterNetEvent('siku_radio:server:checkDevice', function()
  RadioItem.verify(source)
end)

AddEventHandler('siku:server:createCharacterInstance', function(sessionId)
  if type(sessionId) ~= 'number' or not RadioItem.isEnabled() then
    return
  end

  active[sessionId] = nil
  pushDevice(sessionId, nil)

  if InventoryConfig.restoreOnLoad then
    CreateThread(function()
      restore(sessionId)
    end)
  end
end)

AddEventHandler('playerDropped', function()
  active[source] = nil
end)

AddEventHandler('onResourceStart', function(resource)
  if resource == InventoryConfig.resource then
    registered = false
    register()
  end
end)

CreateThread(function()
  Wait(0)

  if not RadioItem.isEnabled() then
    return
  end

  if isInventoryRunning() then
    register()
  else
    Siku.print.warn(T('inventory_missing', InventoryConfig.resource))
  end
end)
