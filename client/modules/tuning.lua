local COMMAND <const> = 'radioanim'
local VECTOR_ARGS <const> = 3

--- Reads three command arguments as a vector.
---@param args table The command arguments.
---@param from number The index of the first component.
---@return vector3? vector The vector, or nil when a component is not a number.
local function readVector(args, from)
  local components <const> = {}

  for i = 1, VECTOR_ARGS do
    local value <const> = tonumber(args[from + i - 1])

    if value == nil then
      return nil
    end

    components[i] = value + 0.0
  end

  return vector3(components[1], components[2], components[3])
end

--- Prints the animation config as it stands, ready to paste in config/device.lua.
---@return nil
local function printAnimation()
  local animation <const> = DeviceConfig.animation

  print(('[siku_radio] dict = %q, anim = %q, bone = %d'):format(
    animation.dict, animation.anim, animation.bone
  ))
  print(('[siku_radio] offset = vector3(%.3f, %.3f, %.3f), rotation = vector3(%.1f, %.1f, %.1f)'):format(
    animation.offset.x, animation.offset.y, animation.offset.z,
    animation.rotation.x, animation.rotation.y, animation.rotation.z
  ))
end

--- Applies one change from the command to the animation config.
---@param args table The command arguments.
---@return boolean changed Whether something was applied.
local function apply(args)
  local animation <const> = DeviceConfig.animation
  local what <const> = args[1]

  if what == 'bone' then
    local bone <const> = tonumber(args[2])

    if bone == nil then
      return false
    end

    animation.bone = math.floor(bone)
    return true
  end

  if what == 'offset' or what == 'rotation' then
    local vector <const> = readVector(args, 2)

    if vector == nil then
      return false
    end

    animation[what] = vector
    return true
  end

  if type(what) == 'string' and type(args[2]) == 'string' then
    animation.dict = what
    animation.anim = args[2]
    return true
  end

  return false
end

--- Changes the pose and the prop live, while the key is held, so the
--- right values are found in the game and copied to the config.
---@param args table The command arguments.
---@return nil
local function handleCommand(_, args)
  if #args == 0 then
    printAnimation()
    return
  end

  if not apply(args) then
    print(('[siku_radio] /%s <dict> <anim> | bone <id> | offset <x> <y> <z> | rotation <x> <y> <z>'):format(COMMAND))
    return
  end

  printAnimation()

  if not RadioTalk.refresh() then
    print('[siku_radio] hold the talk key to see it')
  end
end

if DeviceConfig.animation.tuning == true then
  RegisterCommand(COMMAND, handleCommand, false)
  TriggerEvent('chat:addSuggestion', '/' .. COMMAND, T('command_radioanim_description'))
end
