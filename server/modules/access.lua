RadioAccess = {}

local MODE_EVERYONE <const> = 'everyone'
local MODE_RESTRICTED <const> = 'restricted'
local EVENT_SET_ACCESS <const> = 'siku_radio:client:setAccess'
local MAX_PRESET <const> = 3
local ROLES_POLL <const> = 500
local ROLES_TIMEOUT <const> = 60000

--- Resolves the configured mode, falling back to everyone when the name
--- matches nothing.
---@return string mode 'everyone' or 'restricted'.
local function resolveMode()
  local mode <const> = AccessConfig.mode

  if mode == MODE_EVERYONE or mode == MODE_RESTRICTED then
    return mode
  end

  Siku.print.warn(T('access_unknown_mode', tostring(mode)))

  return MODE_EVERYONE
end

local mode <const> = resolveMode()

--- Whether the core has finished loading its roles.
---@return boolean ready Whether the roles are known.
local function areRolesReady()
  local roles <const> = Siku.permissions.getAllRoles()

  return type(roles) == 'table' and #roles > 0
end

--- Gives the configured roles the permission, once the roles exist.
---@return nil
local function grantRoles()
  local roles <const> = AccessConfig.roles

  if type(roles) ~= 'table' or #roles == 0 then
    return
  end

  local deadline <const> = GetGameTimer() + ROLES_TIMEOUT

  while not areRolesReady() do
    if GetGameTimer() >= deadline then
      return Siku.print.warn(T('access_roles_unavailable'))
    end

    Wait(ROLES_POLL)
  end

  for i = 1, #roles do
    if Siku.permissions.addPermissionToRole(roles[i], AccessConfig.permission) then
      Siku.print.info(T('access_permission_granted', AccessConfig.permission, roles[i]))
    end
  end
end

--- The character a session plays.
---@param sessionId number The player server id.
---@return number? characterId The character id, or nil between two.
local function characterOf(sessionId)
  return Siku.cache.getCurrentCharacterId(sessionId)
end

--- Whether the mode restricts radios to a permission.
---@return boolean restricted Whether a permission is required.
function RadioAccess.isRestricted()
  return mode == MODE_RESTRICTED
end

--- Whether a player may use a radio at all.
---@param sessionId number The player server id.
---@return boolean allowed Whether their character passes the access rule.
function RadioAccess.isAllowed(sessionId)
  if mode == MODE_EVERYONE then
    return true
  end

  local characterId <const> = characterOf(sessionId)

  if not characterId then
    return false
  end

  return Siku.permissions.hasPermission(characterId, AccessConfig.permission) == true
end

--- The jobs a player's character belongs to, by name, asked to the core
--- job engine. Every job counts: a character may hold several.
---@param sessionId number The player server id.
---@return table jobs The list of job names.
function RadioAccess.jobsOf(sessionId)
  local characterId <const> = characterOf(sessionId)

  if not characterId then
    return {}
  end

  local memberships <const> = Siku.jobs.getMemberships(characterId)
  local jobs <const> = {}

  for i = 1, #memberships do
    jobs[i] = memberships[i].job
  end

  return jobs
end

--- Whether a player holds the job a reserved band belongs to, and the
--- permission the band asks for on top when it declares one.
---@param sessionId number The player server id.
---@param band table The reserved band.
---@return boolean holds Whether the band answers to the player.
function RadioAccess.holdsBand(sessionId, band)
  local characterId <const> = characterOf(sessionId)

  if not characterId then
    return false
  end

  if band.permission then
    return Siku.jobs.hasPermission(characterId, band.job, band.permission)
  end

  return Siku.jobs.hasJob(characterId, band.job)
end

--- Whether a player may tune a frequency: any open one when allowed, a
--- reserved one only with its job.
---@param sessionId number The player server id.
---@param frequency number The frequency on the grid.
---@return boolean allowed Whether the frequency is theirs to tune.
function RadioAccess.canTune(sessionId, frequency)
  if not RadioAccess.isAllowed(sessionId) then
    return false
  end

  local band <const> = RadioBands.reserved(frequency)

  if not band then
    return true
  end

  return RadioAccess.holdsBand(sessionId, band)
end

--- The preset keys as a player sees them: each reserved band on a key,
--- and whether the key answers to them.
---@param sessionId number The player server id.
---@return table presets A list of { index, label, frequency, allowed }.
function RadioAccess.presets(sessionId)
  local list <const> = {}

  for index = 1, MAX_PRESET do
    local band <const> = RadioBands.preset(index)

    if band then
      list[#list + 1] = {
        index = index,
        label = band.label,
        frequency = band.frequency,
        allowed = RadioAccess.canTune(sessionId, band.frequency),
      }
    end
  end

  return list
end

--- The access rule as the interface needs it.
---@param sessionId number The player server id.
---@return table access { mode, allowed, jobs, presets }.
function RadioAccess.describe(sessionId)
  return {
    mode = mode,
    allowed = RadioAccess.isAllowed(sessionId),
    jobs = RadioAccess.jobsOf(sessionId),
    presets = RadioAccess.presets(sessionId),
  }
end

--- Sends a player the access rule that applies to them.
---@param sessionId number The player server id.
---@return nil
function RadioAccess.push(sessionId)
  TriggerClientEvent(EVENT_SET_ACCESS, sessionId, RadioAccess.describe(sessionId))
end

--- Pushes the access rule to every player with a character, after a restart.
---@return nil
function RadioAccess.pushAll()
  for _, id in ipairs(GetPlayers()) do
    local sessionId <const> = tonumber(id)

    if sessionId and characterOf(sessionId) then
      RadioAccess.push(sessionId)
    end
  end
end

--- Sends a player their rule again when their jobs moved, and takes them
--- off a band that stopped answering to them.
---@param sessionId? number The player server id, nil when the character is not in play.
---@return nil
local function handleJobsChanged(sessionId)
  if type(sessionId) ~= 'number' then
    return
  end

  local room <const> = RadioRooms.get(sessionId)

  if room and not RadioAccess.canTune(sessionId, room.frequency) then
    RadioRooms.leave(sessionId)
  end

  RadioAccess.push(sessionId)
end

AddEventHandler('siku:server:createCharacterInstance', function(sessionId, characterData)
  if type(sessionId) ~= 'number' or type(characterData) ~= 'table' then
    return
  end

  RadioRooms.leave(sessionId)
  RadioAccess.push(sessionId)
end)

AddEventHandler('siku:jobs:memberAdded', function(_, _, _, sessionId)
  handleJobsChanged(sessionId)
end)

AddEventHandler('siku:jobs:memberRemoved', function(_, _, sessionId)
  handleJobsChanged(sessionId)
end)

AddEventHandler('siku:jobs:gradeChanged', function(_, _, _, _, sessionId)
  handleJobsChanged(sessionId)
end)

AddEventHandler('siku:jobs:dutyChanged', function(sessionId)
  handleJobsChanged(sessionId)
end)

AddEventHandler('siku:jobs:registered', function()
  RadioAccess.pushAll()
end)

AddEventHandler('siku:jobs:deactivated', function()
  RadioAccess.pushAll()
end)

CreateThread(grantRoles)
