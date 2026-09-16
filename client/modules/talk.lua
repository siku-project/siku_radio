RadioTalk = {}

local KEYBIND <const> = 'siku_radio_talk'
local ANIM_FLAG_UPPER_BODY <const> = 50
local ANIM_BLEND_IN <const> = 8.0
local ANIM_BLEND_OUT <const> = -4.0
local ANIM_LOOP <const> = -1
local MODEL_POLL <const> = 10
local MODEL_TIMEOUT <const> = 5000
local BONE_FLAGS <const> = { softPin = true, collision = false, fixedRotation = true }

local prop = nil

--- Loads an animation dictionary and a model, waiting for both.
---@param dict string The dictionary.
---@param model string The prop model.
---@return boolean ready Whether both loaded in time.
local function loadAssets(dict, model)
  local hash <const> = joaat(model)
  local deadline <const> = GetGameTimer() + MODEL_TIMEOUT

  RequestAnimDict(dict)
  RequestModel(hash)

  while not HasAnimDictLoaded(dict) or not HasModelLoaded(hash) do
    if GetGameTimer() >= deadline then
      return false
    end

    Wait(MODEL_POLL)
  end

  return true
end

--- Puts the radio in the hand.
---@return nil
local function attachProp()
  local animation <const> = DeviceConfig.animation
  local ped <const> = PlayerPedId()
  local coords <const> = GetEntityCoords(ped)

  prop = CreateObject(joaat(animation.prop), coords.x, coords.y, coords.z, true, true, false)

  AttachEntityToEntity(
    prop,
    ped,
    GetPedBoneIndex(ped, animation.bone),
    animation.offset.x, animation.offset.y, animation.offset.z,
    animation.rotation.x, animation.rotation.y, animation.rotation.z,
    BONE_FLAGS.softPin, BONE_FLAGS.softPin, BONE_FLAGS.collision, false, 2, BONE_FLAGS.fixedRotation
  )

  SetModelAsNoLongerNeeded(joaat(animation.prop))
end

--- Takes the radio out of the hand.
---@return nil
local function detachProp()
  if prop and DoesEntityExist(prop) then
    DetachEntity(prop, true, true)
    DeleteEntity(prop)
  end

  prop = nil
end

--- Whether the animation may play right now.
---@return boolean allowed Whether the pose is wanted.
local function canAnimate()
  local animation <const> = DeviceConfig.animation

  if not animation.enabled then
    return false
  end

  if not animation.inVehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
    return false
  end

  return true
end

--- Raises the radio to the mouth for as long as the transmission runs.
---@return nil
local function animate()
  local animation <const> = DeviceConfig.animation

  if not loadAssets(animation.dict, animation.prop) then
    return
  end

  if not RadioState.isTalking() then
    return
  end

  attachProp()

  while RadioState.isTalking() do
    local ped <const> = PlayerPedId()

    if not IsEntityPlayingAnim(ped, animation.dict, animation.anim, 3) then
      TaskPlayAnim(
        ped, animation.dict, animation.anim,
        ANIM_BLEND_IN, ANIM_BLEND_OUT, ANIM_LOOP, ANIM_FLAG_UPPER_BODY, 0.0,
        false, false, false
      )
    end

    Wait(100)
  end

  StopAnimTask(PlayerPedId(), animation.dict, animation.anim, ANIM_BLEND_OUT)
  RemoveAnimDict(animation.dict)
  detachProp()
end

--- Starts a transmission, when the device allows one.
---@return boolean started Whether the key opened the microphone.
function RadioTalk.start()
  if RadioState.isTalking() or not RadioVoice.canTransmit() then
    return false
  end

  RadioState.setTalking(true)
  RadioVoice.startTransmit()
  RadioNui.pushState({ transmitting = true })
  RadioHud.sync()

  if canAnimate() then
    CreateThread(animate)
  end

  return true
end

--- Ends a transmission.
---@return nil
function RadioTalk.stop()
  if not RadioState.isTalking() then
    return
  end

  RadioState.setTalking(false)
  RadioVoice.stopTransmit()
  RadioNui.pushState({ transmitting = false })
  RadioHud.sync()
end

if type(DeviceConfig.keybinds.talk) == 'string' and DeviceConfig.keybinds.talk ~= '' then
  Siku.keybind.add({
    name = KEYBIND,
    description = T('keybind_talk'),
    defaultKey = DeviceConfig.keybinds.talk,
    onPressed = function()
      RadioTalk.start()
    end,
    onReleased = function()
      RadioTalk.stop()
    end,
  })
end

AddEventHandler('onResourceStop', function(resource)
  if resource ~= Siku.name then
    return
  end

  RadioTalk.stop()
  detachProp()
end)
