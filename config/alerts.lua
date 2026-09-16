AlertConfig = {
  --- Enabled
  ---
  --- Whether the emergency alert exists at all. Off, the menu entry
  --- disappears and the server refuses every alert.
  ---
  --- Default: true
  enabled = true,

  --- Cooldown
  ---
  --- How long (seconds) a player waits before raising another alert.
  ---
  --- Default: 30
  cooldown = 30,

  --- Auto stop
  ---
  --- How long (seconds) an alert rings on a receiving device before it
  --- stops on its own. 0 keeps it ringing until the player opens their
  --- radio and presses STOP, which is the point of an alert.
  ---
  --- Default: 0
  autoStop = 0,
}
