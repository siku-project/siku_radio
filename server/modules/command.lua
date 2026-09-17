local CONSOLE <const> = 0

--- The command only exists when radios come without an item: with the
--- inventory, using the radio item is what takes it in hand.
---@return nil
local function registerCommand()
  Siku.command.register('radio', function(source)
    if source == CONSOLE then
      return
    end

    TriggerClientEvent('siku_radio:client:toggle', source)
  end, {
    description = T('command_radio_description'),
  })
end

if not RadioItem.isEnabled() then
  registerCommand()
end
