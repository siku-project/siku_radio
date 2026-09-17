InventoryConfig = {
  --- Mode
  ---
  --- Where a radio comes from.
  ---
  --- • 'command': no item is involved. /radio and the open key show the
  ---   device to anyone the access rule allows, as before. Using a radio
  ---   item from an inventory does nothing.
  --- • 'item': the radio is the item below, carried in siku_inventory.
  ---   /radio does not exist, using the item takes it in hand, powers it
  ---   on and opens it. Each radio remembers its own state in its
  ---   metadata (on or off, frequency, channel, volume), so one handed to
  ---   another player arrives as it was left. A radio given away, dropped
  ---   or stored is no longer heard nor spoken into.
  ---
  --- Available: 'command', 'item'
  ---
  --- Default: 'command'
  mode = 'command',

  --- Resource
  ---
  --- The inventory the item lives in. Never a hard dependency: the radio
  --- starts without it and only talks to it once it runs.
  ---
  --- Default: 'siku_inventory'
  resource = 'siku_inventory',

  --- Item
  ---
  --- The item identifier in the inventory catalogue.
  ---
  --- Default: 'radio'
  item = 'radio',

  --- Restore on load
  ---
  --- Whether a radio left powered on in the pocket comes back on the air
  --- when the character loads, without being used first. Off, every
  --- session starts with the radio in the pocket and silent.
  ---
  --- Default: true
  restoreOnLoad = true,
}
