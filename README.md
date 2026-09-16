# siku_radio

A modern, immersive radio system for the SIKU ecosystem — featuring a realistic in-device interface, channel management, player communication, and a clean, modular architecture built for high-quality FiveM roleplay.

![Version](https://img.shields.io/badge/version-1.0.0-4785bd)
![FiveM](https://img.shields.io/badge/fx__version-cerulean-4785bd)
![Lua](https://img.shields.io/badge/Lua-5.4-4785bd)
![Svelte](https://img.shields.io/badge/Svelte-5-4785bd)

Built on [`siku_voice`](https://github.com/siku-project/siku_voice): the radio owns the frequencies, the members and the device, the voice owns the routing, the effects and the restrictions.

## Features

- **A real handheld** — the device sits at the bottom right, boots once per session with its own sequence, and every physical key is clickable: MENU, BACK, SCAN, VFO/MR, the dial, P1 to P3 and the keypad. Arrows, Enter and the digits work from the keyboard too, and Escape puts the radio away. While it is open the player keeps walking, but the game lets go of the mouse and of every key the display reads: no camera turn, no shot on a click, no weapon slot on a digit, no phone on an arrow, no pause menu on Escape (`DeviceConfig.focus.controls`).
- **Frequencies and channels** — reserved bands belong to a job (LSPD and EMS out of the box) and carry named channels; every other frequency is open, the frequency being the channel, or carrying numbered channels by configuration. The keypad types a frequency, `#` tunes it, `*` erases.
- **Presets** — P1 to P3 jump to a reserved band, and only answer to a player holding its job. No job resource exists yet: the core roles stand in, and a resolver hook is ready for one.
- **Push to talk through siku_voice** — Left Alt by default, rebindable, working with the device closed: the transmission rides a voice route to the members of the frequency, the microphone is held through the voice, and everyone hears the talker through the radio effect at their own device volume. A dead or cuffed player, closed by a voice restriction, cannot transmit.
- **Animation and prop** — the radio in the hand, raised to the mouth while transmitting.
- **Sounds** — mic clicks, squelch on reception, key tones, boot, alert, all switchable from the device settings.
- **A working menu** — frequency, channels, recents, scan, volume, leave the frequency, emergency alert, settings, info, power off. The menu shows each player what they can use: a citizen never sees the alert, nor the channels when open frequencies are single (a service member always does, for their own bands), and the frequency is only left once one is tuned. Power off leaves the frequency, puts the device away and boots it again the next time. On a band with channels the arrows switch channel from the home screen, and VFO/MR steps to the next one.
- **Emergency alert** — a member of a service raises it in one press of the orange button at the base of the antenna, live only on their own band, or from the menu, and every device tuned to any band of that service, on any channel, rings a radio siren and shows who, where and since when. It rings in the pocket too: the player opens their radio and presses STOP. A cooldown, an optional auto stop, and a switch to turn the whole thing off live in `config/alerts.lua`.
- **Toasts** — the device's own toasts, shadcn sonner in the ecosystem's look, whether the radio is open or in the pocket.
- **Per session** — nothing is written to the database: a player starts fresh each time.

## Dependencies

| Resource | Required | Purpose |
|---|---|---|
| [`siku_core`](https://github.com/siku-project/siku_core) | Yes | Framework core: SDK, keybinds, commands, permissions, roles, locale. |
| [`siku_voice`](https://github.com/siku-project/siku_voice) | Yes | Routes, microphone hold, the radio effect, the `radio` restriction scope. |
| [`siku_hud`](https://github.com/siku-project/siku_hud) | No | Receives the frequency and the transmitting state through `SetRadio`. |

## Configuration

| File | Options |
|---|---|
| `config/access.lua` | `mode` everyone / restricted, `permission`, `roles`, `jobs` (`resolver` roles / export, `export`) |
| `config/frequencies.lua` | `range`, `step`, `reserved` bands with `job`, `preset` and `channels`, `open` mode single / channels |
| `config/device.lua` | `keybinds` (`talk`, `open`), `volume` (`default`, `step`), `voice` (`effect`, `priority`), `animation`, `sounds`, `boot`, `display` (`clock24h`, durations), `scan.dwell` |
| `config/alerts.lua` | `enabled`, `cooldown` (seconds), `autoStop` (seconds, 0 to ring until STOP) |
| `config/translation.lua` | `language` (`fr` / `en`) |

The device config travels to the interface with the access rule and the frequencies, so a value changed in Lua changes the device without touching the web.

### Keys

| Key | Action |
|---|---|
| `Left Alt` | Held to transmit on the tuned frequency. |
| `/radio` | Opens or closes the device, until the inventory item takes over. |
| Arrows, Enter | Walk the menu and pick. On the home screen the arrows switch channel, or the volume on a single-channel frequency. |
| Escape | Closes the radio, whatever screen it shows. The BACK key goes one screen back instead. |
| `+` / `-` | The volume, from any screen. |
| Digits, `Backspace`, `Enter` | Type a frequency, erase, tune. |

### Access

`access.mode` decides who may hold a radio at all. `everyone` opens it to any character; `restricted` keeps it to characters holding `access.permission`, granted at startup to the roles listed in `access.roles`. Reserved bands add a second gate on top: their job.

## API

### Server exports

| Export | Arguments | Purpose |
|---|---|---|
| `GetPlayerRadio` | `sessionId` | `{ frequency?, channel?, key?, talking, allowed, job }`. |
| `TunePlayer` / `UntunePlayer` | `sessionId, frequency, channel?` / `sessionId` | Puts a player on a frequency with the device's checks, or off the air. |
| `GetMembers` | `frequency, channel?` | The server ids on a frequency and channel. |
| `SetPlayerRadioOpen` | `sessionId, open` | Shows or hides a player's device. |
| `SetJobResolver` | `resolver?` | Lets a job resource answer `(sessionId) -> job` in place of the roles. |
| `RefreshAccess` | — | Sends every player their access rule again, after jobs changed. |

### Client exports

| Export | Purpose |
|---|---|
| `Open` / `Close` / `Toggle` / `IsOpen` | The device on screen. |
| `PowerOff` | Ends the transmission, leaves the frequency and puts the device away. |
| `GetTuned` / `Tune` / `Leave` | Where the device is, and moving it. |
| `IsTalking` / `StartTalking` / `StopTalking` | The transmission, as the key does it. |
| `GetVolume` / `SetVolume` | The device volume, 0 to 100. |

### Events

| Event | Side | Arguments | When |
|---|---|---|---|
| `siku:radio:playerTuned` | server | `sessionId, frequency?, channel?` | A player tuned a frequency, or left it. |
| `siku:radio:alert` | server | `sessionId, frequency, channel` | A player raised an emergency alert to their whole service. |
| `siku:radio:tuned` | client | `room?` | The local device landed on a frequency, or left it. |
| `siku:radio:receivingChanged` | client | `receiving` | Someone started or stopped transmitting to the player. |

## Translations

Every string lives in `translations/fr.lua` and `translations/en.lua`, the interface ones in their `web` block, like every other resource. The game pushes the block of the configured language to the interface at startup, so a wording edited in Lua shows without a rebuild.

The interface is typed by [Paraglide](https://paraglidejs.com): `web/messages/<language>.json` is generated from the Lua files by `bun run locales`, run by `dev` and `build` on its own, and the pushed strings win over the compiled ones at runtime. Adding a key means adding it to both Lua files, then rebuilding; `bun run check` refuses a JSON that fell behind.

## Development

The interface lives in `web/`, a Svelte 5 application built with Vite, Tailwind 3 and shadcn-svelte. It is the first Svelte NUI of the ecosystem.

```bash
cd web
bun install
bun run dev      # the interface in the browser
bun run build    # production build into web/dist, served by ui_page
bun run check    # locales, format, types, lints
bun run locales  # regenerate web/messages from translations/*.lua
```

In the browser the device simulates the game: `?view=Radio` opens it, `?screen=menu` a given screen, `?job=police` gives a job, `?access=restricted&allowed=0` refuses the player, `?tune=155.475&channel=2` presets a frequency, `?entry=1554` types on the keypad, `?keys` outlines the clickable keys, `?toast=tuned` or `?toast=alert` shows a toast. The simulation panel, bottom left, does the same with switches.

## Structure

```
siku_radio/
├── client/modules/    # state, nui, voice, hud, talk, ui, events, api
├── server/modules/    # jobs, access, rooms, command, api
├── shared/            # locale, bands
├── config/            # behavior, language
├── translations/      # fr / en
└── web/               # the Svelte interface
```

## Credits

Part of the [SIKU project](https://github.com/siku-project) — © Siku Studio.
