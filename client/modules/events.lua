local EVENT_TUNED <const> = 'siku:radio:tuned'
local EVENT_RECEIVING <const> = 'siku:radio:receivingChanged'

RegisterNetEvent('siku_radio:client:setAccess', function(rule)
  if type(rule) ~= 'table' then
    return
  end

  RadioState.setAccess(rule)
  RadioNui.pushConfig()

  if not RadioState.isAllowed() then
    RadioTalk.stop()
  end
end)

RegisterNetEvent('siku_radio:client:setRoom', function(room)
  RadioTalk.stop()
  RadioState.setRoom(room)
  RadioVoice.syncMembers()

  if not room then
    RadioVoice.clear()
  end

  RadioNui.pushState({ tuned = RadioState.room(), receiving = false })
  RadioHud.sync()

  TriggerEvent(EVENT_TUNED, RadioState.room())
end)

RegisterNetEvent('siku_radio:client:setMembers', function(key, members)
  local room <const> = RadioState.room()

  if not room or room.key ~= key then
    return
  end

  RadioState.setMembers(members)
  RadioVoice.syncMembers()
  RadioNui.pushState({ receiving = RadioState.isReceiving() })
end)

RegisterNetEvent('siku_radio:client:setTalking', function(id, talking)
  local room <const> = RadioState.room()

  if not room or type(id) ~= 'number' then
    return
  end

  local before <const> = RadioState.isReceiving()

  RadioState.setReceiving(id, talking == true)
  RadioVoice.setReceiving(id, talking == true)

  local after <const> = RadioState.isReceiving()

  RadioNui.pushState({ receiving = after })

  if before ~= after then
    TriggerEvent(EVENT_RECEIVING, after)
  end
end)

RegisterNetEvent('siku_radio:client:tuneRefused', function(reason)
  RadioNui.pushEvent('refused', { reason = reason })
end)

RegisterNetEvent('siku_radio:client:alert', function(alert)
  if type(alert) ~= 'table' then
    return
  end

  RadioNui.pushEvent('alert', alert)
end)

RegisterNetEvent('siku_radio:client:alertSent', function(alert)
  if type(alert) ~= 'table' then
    return
  end

  RadioNui.pushEvent('alertSent', alert)
end)

RegisterNetEvent('siku_radio:client:alertRefused', function(reason)
  RadioNui.pushEvent('alertRefused', { reason = reason })
end)

AddEventHandler('onResourceStop', function(resource)
  if resource == Siku.name then
    RadioVoice.clear()
  end
end)
