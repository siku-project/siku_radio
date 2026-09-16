RadioJobs = {}

local RESOLVER_ROLES <const> = 'roles'
local RESOLVER_EXPORT <const> = 'export'

local custom = nil

--- The job read from the core roles: the first role named after a job
--- appearing in a reserved band, so a role called 'police' is the police.
---@param sessionId number The player server id.
---@return string? job The job name, or nil.
local function fromRoles(sessionId)
  local character <const> = Siku.cache.getCurrentCharacter(sessionId)

  if not character or type(character.id) ~= 'number' then
    return nil
  end

  local roles <const> = Siku.permissions.getCharacterRoles(character.id)
  local bands <const> = RadioBands.list()

  for i = 1, #roles do
    local name <const> = type(roles[i]) == 'table' and roles[i].name or roles[i]

    for j = 1, #bands do
      if bands[j].job == name then
        return name
      end
    end
  end

  return nil
end

--- The job read from the configured export of another resource.
---@param sessionId number The player server id.
---@return string? job The job name, or nil.
local function fromExport(sessionId)
  local target <const> = AccessConfig.jobs.export

  if type(target) ~= 'table' or type(target.resource) ~= 'string' or type(target.name) ~= 'string' then
    return nil
  end

  local ok <const>, job <const> = pcall(function()
    return exports[target.resource][target.name](nil, sessionId)
  end)

  if ok and type(job) == 'string' and job ~= '' then
    return job
  end

  return nil
end

--- The job of a player, through the resolver a resource registered, or the
--- configured one.
---@param sessionId number The player server id.
---@return string? job The job name, or nil when the player has none.
function RadioJobs.get(sessionId)
  if custom then
    local ok <const>, job <const> = pcall(custom, sessionId)

    if ok and type(job) == 'string' and job ~= '' then
      return job
    end

    return nil
  end

  if AccessConfig.jobs.resolver == RESOLVER_EXPORT then
    return fromExport(sessionId)
  end

  if AccessConfig.jobs.resolver ~= RESOLVER_ROLES then
    Siku.print.warn(T('jobs_unknown_resolver', tostring(AccessConfig.jobs.resolver)))
  end

  return fromRoles(sessionId)
end

--- Whether a player holds a job.
---@param sessionId number The player server id.
---@param job string The job name.
---@return boolean holds Whether the jobs match.
function RadioJobs.has(sessionId, job)
  return RadioJobs.get(sessionId) == job
end

--- Lets a job resource decide the job of a player, in place of the
--- configured resolver. Pass nil to go back to it.
---@param resolver function? Receives the server id, returns the job name or nil.
---@return boolean applied Whether the resolver was stored.
function RadioJobs.setResolver(resolver)
  if resolver ~= nil and not Siku.isCallable(resolver) then
    return false
  end

  custom = resolver

  return true
end
