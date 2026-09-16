FrequencyConfig = {
  --- Range
  ---
  --- What the keypad accepts, in MHz. The keypad types three digits, a
  --- point and three digits, so the widest range it can reach is 100.000
  --- to 999.995. Narrow it to keep players on a realistic band.
  ---
  --- Default: 100.000 to 999.995
  range = { min = 100.0, max = 999.995 },

  --- Step
  ---
  --- The grid a typed frequency snaps to, in MHz.
  ---
  --- Default: 0.005
  step = 0.005,

  --- Reserved
  ---
  --- The bands owned by a job. Nobody else can tune them, and the preset
  --- key (`preset`, 1 to 3) jumps to them. The channels are listed in
  --- order and walked with the arrows; a band without any has one.
  reserved = {
    {
      frequency = 155.475,
      label = 'LSPD',
      job = 'police',
      preset = 1,
      channels = { 'Dispatch', 'Patrol', 'Tactical', 'Detectives' },
    },
    {
      frequency = 155.340,
      label = 'EMS',
      job = 'ems',
      preset = 2,
      channels = { 'Dispatch', 'Field', 'Hospital' },
    },
  },

  --- Open
  ---
  --- How every other frequency works.
  ---
  --- • 'single': the frequency is the channel, whoever tunes it is
  ---   together. The simplest, and the default.
  --- • 'channels': every open frequency carries `count` numbered channels,
  ---   walked with the arrows like a reserved band.
  ---
  --- Available: 'single', 'channels'
  ---
  --- Default: 'single'
  open = { mode = 'single', count = 4 },
}
