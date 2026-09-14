fx_version 'cerulean'
game 'gta5'

author 'Siku Studio'
description 'A modern, immersive radio system for the SIKU ecosystem — featuring a realistic in-device interface, channel management, player communication, and a clean, modular architecture built for high-quality FiveM roleplay.'
version '0.1.0'

name 'siku_radio'

lua54 'yes'

ui_page 'web/dist/index.html'

files {
  'web/dist/**/*',
}

dependencies {
  'siku_core',
  'siku_voice',
}
