AccessConfig = {
  --- Mode
  ---
  --- Who may hold a radio at all. The server decides for every character
  --- and tells the interface, which shows a locked device to anyone
  --- refused. Reserved frequencies add their own gate on top: a job.
  ---
  --- • 'everyone': any character can use a radio.
  --- • 'restricted': only characters holding the permission below, meant
  ---   for emergency services.
  ---
  --- Available: 'everyone', 'restricted'
  ---
  --- Default: 'everyone'
  mode = 'everyone',

  --- Permission
  ---
  --- The permission checked in 'restricted' mode, through the core roles.
  ---
  --- Default: 'radio.use'
  permission = 'radio.use',

  --- Roles
  ---
  --- The roles given the permission at startup, each of them a core role
  --- that must exist. Roles inherit down the primary chain. Leave the list
  --- empty to attach the permission yourself.
  ---
  --- Default: { 'police', 'ems' }
  roles = { 'police', 'ems' },

  --- Jobs
  ---
  --- How the job of a character is found, which decides the reserved
  --- frequencies and the preset keys they may use. No job resource exists
  --- yet, so the default reads the core roles: a character holding a role
  --- named after a job has that job. A job resource plugs in either
  --- through the export below or through the SetJobResolver export.
  jobs = {
    --- • 'roles': a core role named after the job.
    --- • 'export': the export below, called with the server id, returning
    ---   the job name or nil.
    ---
    --- Available: 'roles', 'export'
    ---
    --- Default: 'roles'
    resolver = 'roles',

    --- Only read with the 'export' resolver.
    export = { resource = false, name = false },
  },
}
