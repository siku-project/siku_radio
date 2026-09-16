RadioHud = {}

local HUD_RESOURCE <const> = 'siku_hud'
local STARTED <const> = 'started'

--- Hands the HUD the radio card: the frequency, the channel, whether the
--- player transmits. Nothing happens when the HUD is not running.
---@return nil
function RadioHud.sync()
  if GetResourceState(HUD_RESOURCE) ~= STARTED then
    return
  end

  local room <const> = RadioState.room()

  pcall(function()
    if not room then
      exports[HUD_RESOURCE]:SetRadio({ active = false, transmitting = false })
      return
    end

    exports[HUD_RESOURCE]:SetRadio({
      active = true,
      channel = ('%.3f'):format(room.frequency),
      label = room.channelLabel and (room.label and (room.label .. ' · ' .. room.channelLabel) or room.channelLabel)
        or room.label
        or '',
      transmitting = RadioState.isTalking(),
    })
  end)
end
