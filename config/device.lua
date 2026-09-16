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

  --- Focus
  ---
  --- The device takes the pointer while it is open, and the player keeps
  --- moving. Everything listed here is disabled in the meantime so a click
  --- never fires, the mouse never turns the camera, and the keys the
  --- display reads (digits, arrows, Enter, Escape, M) never reach the
  --- game: weapon slots, phone, pause menu, interaction menu.
  focus = {
    controls = {
      --- Camera: look, next camera, look behind.
      1, 2, 0, 26,
      --- Combat: attack, aim, weapon wheel, reload, cover, detonate,
      --- grenade, melee, secondary attack.
      24, 25, 37, 45, 44, 47, 58, 140, 141, 142, 143, 257, 263, 264,
      --- Weapon selection: scroll and the digit keys.
      14, 15, 16, 17, 157, 158, 159, 160, 161, 162, 163, 164, 165, 261, 262,
      --- Vehicle combat and mouse steering.
      68, 69, 70, 92, 114, 106,
      --- The keys the display reads: the arrows (phone and its
      --- navigation), Enter (talk, accept, select), Backspace (cancel).
      27, 172, 173, 174, 175, 176, 177, 18, 201, 194,
      --- Frontend: pause menu (Escape), cancel, interaction menu, chat.
      199, 200, 202, 244, 245, 246,
    },
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

    --- The prop, the bone it hangs from (57005 is the right hand), and
    --- where it sits on it.
    prop = 'prop_cs_hand_radio',
    bone = 57005,
    offset = vector3(0.14, 0.01, -0.02),
    rotation = vector3(110.0, -10.0, 160.0),

    --- The pose, upper body only so the player keeps walking: the right
    --- hand holds the radio up at the face for as long as the key is held.
    --- The 'random@arrests' clips are the police ones, the left hand on
    --- the shoulder mic, whatever the prop does in the right hand.
    dict = 'cellphone@',
    anim = 'cellphone_call_listen_base',

    --- Tuning
    ---
    --- Set to true to get the client command /radioanim, which changes
    --- the pose and the prop live while the key is held:
    ---   /radioanim                       prints the current values
    ---   /radioanim <dict> <anim>         another pose
    ---   /radioanim bone <id>             another bone
    ---   /radioanim offset <x> <y> <z>    moves the prop on the bone
    ---   /radioanim rotation <x> <y> <z>  turns it
    --- Copy the printed values here once it looks right.
    ---
    --- Default: false
    tuning = false,

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
