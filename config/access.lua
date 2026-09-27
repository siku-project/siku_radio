AccessConfig = {
  --- Mode
  ---
  --- Who may hold a radio at all. The server decides for every character
  --- and tells the interface, which shows a locked device to anyone
  --- refused. Reserved frequencies add their own gate on top: the job
  --- they belong to, asked to the core job engine.
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
}
