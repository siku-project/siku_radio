import { config } from '@/lib/config.svelte'

export interface RadioRoom {
  key: string
  frequency: number
  channel: number
  label: string | null
  channelLabel: string | null
}

export interface RadioState {
  visible: boolean
  powered: boolean
  booted: boolean
  tuned: RadioRoom | null
  transmitting: boolean
  receiving: boolean
  scanning: boolean
  /** 0 to 100. */
  volume: number
  /** 0 to 4 bars. */
  signal: number
  /** 0 to 100. */
  battery: number
}

const MAX_RECENTS = 8
const ENTRY_DIGITS = 6

const initial: RadioState = {
  visible: import.meta.env.DEV,
  powered: true,
  booted: false,
  tuned: null,
  transmitting: false,
  receiving: false,
  scanning: false,
  volume: config.device.volume.default,
  signal: 3,
  battery: 82,
}

/** In the browser, `?tune=155.475&channel=2` and `?entry=1554` preset the device. */
const devPreset = (): { tuned: RadioRoom | null; entry: string } => {
  if (!import.meta.env.DEV) {
    return { tuned: null, entry: '' }
  }

  const params = new URLSearchParams(window.location.search)
  const frequency = Number.parseFloat(params.get('tune') ?? '')
  const channel = Number.parseInt(params.get('channel') ?? '1', 10) || 1
  const band = config.band(frequency)
  const channels = config.channels(frequency)

  return {
    tuned: Number.isFinite(frequency)
      ? {
          key: `${frequency.toFixed(3)}/${channel}`,
          frequency,
          channel,
          label: band?.label ?? null,
          channelLabel: channels[channel - 1] ?? null,
        }
      : null,
    entry: (params.get('entry') ?? '').replace(/\D/g, '').slice(0, ENTRY_DIGITS),
  }
}

const preset = devPreset()

let state = $state<RadioState>({ ...initial, tuned: preset.tuned })
let recents = $state<number[]>(preset.tuned ? [preset.tuned.frequency] : [])
let entry = $state(preset.entry)

/** What the device shows. The game patches it, the interface only reads it. */
export const radio = {
  get state(): RadioState {
    return state
  },

  /** Whether the display is running its power-on sequence. */
  get booting(): boolean {
    return config.device.boot.enabled && state.visible && state.powered && !state.booted
  },

  /** The frequencies tuned this session, latest first. */
  get recents(): number[] {
    return recents
  },

  /** The digits typed on the keypad, up to six. */
  get entry(): string {
    return entry
  },

  /** The typed digits as a frequency, `155475` reading as 155.475. */
  get entryFrequency(): number | null {
    if (entry.length < 3) {
      return null
    }

    const whole = Number(entry.slice(0, 3))
    const fraction = entry.slice(3).padEnd(3, '0')

    return whole + Number(fraction) / 1000
  },

  /**
   * A state patch from the game. Off the air travels as `tuned: false`,
   * since a nil key would vanish from the Lua table on the way.
   */
  patch(changes: Omit<Partial<RadioState>, 'tuned'> & { tuned?: RadioRoom | null | false }): void {
    const tuned = changes.tuned === false ? null : changes.tuned

    state = { ...state, ...changes, tuned: tuned === undefined ? state.tuned : tuned }

    if (tuned) {
      radio.remember(tuned.frequency)
    }
  },

  setVisible(visible: boolean): void {
    state.visible = visible
  },

  finishBoot(): void {
    state.booted = true
  },

  reboot(): void {
    state.booted = false
  },

  clampVolume(value: number): number {
    return Math.max(0, Math.min(100, Math.round(value)))
  },

  stepVolume(direction: 1 | -1): number {
    return radio.clampVolume(state.volume + direction * config.device.volume.step)
  },

  setScanning(value: boolean): void {
    state.scanning = value
  },

  remember(frequency: number): void {
    recents = [frequency, ...recents.filter((known) => known !== frequency)].slice(0, MAX_RECENTS)
  },

  typeDigit(digit: string): void {
    if (/^\d$/.test(digit) && entry.length < ENTRY_DIGITS) {
      entry += digit
    }
  },

  eraseDigit(): void {
    entry = entry.slice(0, -1)
  },

  clearEntry(): void {
    entry = ''
  },
}
