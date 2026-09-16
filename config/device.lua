DeviceConfig = {
  --- Keybinds
  ---
  --- Default keys, registered through the core so every player can rebind
  --- them in the game settings. Set one to false to register no keybind.
  keybinds = {
    --- Held to transmit on the tuned frequency. Works with the device
    --- closed: a radio in a pocket still talks.
    ---
    --- Default: 'LMENU' (left Alt)
    talk = 'LMENU',

    --- Opens and closes the device. The inventory item does the same, so
    --- this stays off unless a server wants a key.
    ---
    --- Default: false
    open = false,
  },

  --- Volume
  ---
  --- The device volume scales how loud a transmission is heard through
  --- the voice, 0 to 100.
  volume = {
    --- What a device starts at each session.
    ---
    --- Default: 70
    default = 70,

    --- What one press of the arrows moves it by.
    ---
    --- Default: 5
    step = 5,
  },

  --- Voice
  ---
  --- How a transmission is heard, through siku_voice.
  voice = {
    --- The siku_voice effect rendered on whoever transmits.
    ---
    --- Default: 'radio'
    effect = 'radio',

    --- The rendering layer priority, above a phone call.
    ---
    --- Default: 5
    priority = 5,
  },

  --- Animation
  ---
  --- The radio in the hand and the hand at the mouth while transmitting.
  animation = {
    enabled = true,

    --- The prop, the bone it hangs from, and where it sits on it.
    prop = 'prop_cs_hand_radio',
    bone = 57005,
    offset = vector3(0.14, 0.01, -0.02),
    rotation = vector3(110.0, -10.0, -20.0),

    --- The pose.
    dict = 'random@arrests',
    anim = 'generic_radio_enter',

    --- Whether the pose plays inside a vehicle.
    ---
    --- Default: false
    inVehicle = false,
  },

  --- Sounds
  ---
  --- What the device plays, each family switchable by the player from the
  --- settings screen. These are the values a session starts with.
  sounds = {
    --- Clicks when the transmission opens and closes.
    micClicks = true,

    --- A tone on every key.
    keyTones = true,

    --- The squelch when someone starts and stops transmitting.
    reception = true,
  },

  --- Boot
  ---
  --- The power-on sequence shown the first time the device opens in a
  --- session.
  boot = {
    enabled = true,
  },

  --- Display
  ---
  --- Small choices on the screen.
  display = {
    --- Whether the clock reads 24 hours.
    ---
    --- Default: true
    clock24h = true,

    --- How long (ms) a line stays on the display after an event.
    ---
    --- Default: 2200
    noticeDuration = 2200,

    --- How long (ms) a toast stays on screen, and an alert.
    ---
    --- Default: 3200 and 6000
    toastDuration = 3200,
    alertDuration = 6000,
  },

  --- Scan
  ---
  --- How long (ms) the device stays on each frequency while scanning the
  --- recents.
  ---
  --- Default: 2500
  scan = {
    dwell = 2500,
  },
}
