local CONSOLE <const> = 0

Siku.command.register('radio', function(source)
  if source == CONSOLE then
    return
  end

  TriggerClientEvent('siku_radio:client:toggle', source)
end, {
  description = T('command_radio_description'),
})
