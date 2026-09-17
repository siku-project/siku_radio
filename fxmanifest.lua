fx_version 'cerulean'
game 'gta5'

author 'Siku Studio'
description 'A modern, immersive radio system for the SIKU ecosystem — featuring a realistic in-device interface, channel management, player communication, and a clean, modular architecture built for high-quality FiveM roleplay.'
version '1.0.0'

name 'siku_radio'

lua54 'yes'

shared_scripts {
  '@siku_core/init.lua',
  'config/translation.lua',
  'config/access.lua',
  'config/frequencies.lua',
  'config/device.lua',
  'config/alerts.lua',
  'config/inventory.lua',
  'shared/locale.lua',
  'shared/bands.lua',
}

server_scripts {
  'server/init.lua',
  'server/modules/jobs.lua',
  'server/modules/access.lua',
  'server/modules/rooms.lua',
  'server/modules/item.lua',
  'server/modules/command.lua',
  'server/modules/api.lua',
}

client_scripts {
  'client/modules/state.lua',
  'client/modules/nui.lua',
  'client/modules/voice.lua',
  'client/modules/hud.lua',
  'client/modules/talk.lua',
  'client/modules/tuning.lua',
  'client/modules/ui.lua',
  'client/modules/item.lua',
  'client/modules/events.lua',
  'client/modules/api.lua',
}

ui_page 'web/dist/index.html'

files {
  'translations/*.lua',
  'web/dist/**/*',
}

dependencies {
  'siku_core',
  'siku_voice',
}
