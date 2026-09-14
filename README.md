# siku_radio

A modern, immersive radio system for the SIKU ecosystem — featuring a realistic in-device interface, channel management, player communication, and a clean, modular architecture built for high-quality FiveM roleplay.

![Version](https://img.shields.io/badge/version-0.1.0-4785bd)
![FiveM](https://img.shields.io/badge/fx__version-cerulean-4785bd)
![Lua](https://img.shields.io/badge/Lua-5.4-4785bd)
![Svelte](https://img.shields.io/badge/Svelte-5-4785bd)

Built on [`siku_voice`](https://github.com/siku-project/siku_voice): the radio owns the channels and the device, the voice owns the routing, the effects and the restrictions.

## Dependencies

| Resource | Required | Purpose |
|---|---|---|
| [`siku_core`](https://github.com/siku-project/siku_core) | Yes | Framework core: SDK, keybinds, callbacks, commands, permissions. |
| [`siku_voice`](https://github.com/siku-project/siku_voice) | Yes | Routes, microphone hold, the radio effect, the `radio` restriction scope. |

## Development

The interface lives in `web/`, a Svelte 5 application built with Vite. It is the first Svelte NUI of the ecosystem.

```bash
cd web
bun install
bun run dev      # the interface in the browser
bun run build    # production build into web/dist, served by ui_page
bun run check    # format, types, lints
```

## Structure

```
siku_radio/
├── client/            # game side
├── server/            # authority: channels, members, access
├── config/            # behavior, language
├── translations/      # fr / en
└── web/               # the Svelte interface
```

## Credits

Part of the [SIKU project](https://github.com/siku-project) — © Siku Studio.
