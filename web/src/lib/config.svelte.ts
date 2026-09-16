export type AccessMode = 'everyone' | 'restricted'

export interface RadioPreset {
  index: number
  label: string
  frequency: number
  allowed: boolean
}

export interface RadioAccess {
  mode: AccessMode
  allowed: boolean
  job: string | null
  presets: RadioPreset[]
}

export interface ReservedBand {
  frequency: number
  label: string
  job: string
  preset: number | null
  channels: string[]
}

export interface RadioFrequencies {
  range: { min: number; max: number }
  step: number
  open: { mode: 'single' | 'channels'; count: number }
  reserved: ReservedBand[]
}

export interface DeviceSounds {
  micClicks: boolean
  keyTones: boolean
  reception: boolean
}

export interface RadioDevice {
  volume: { default: number; step: number }
  sounds: DeviceSounds
  boot: { enabled: boolean }
  display: {
    clock24h: boolean
    noticeDuration: number
    toastDuration: number
    alertDuration: number
  }
  scan: { dwell: number }
}

export interface RadioAlerts {
  enabled: boolean
  /** Seconds before a ringing alert stops on its own, 0 for never. */
  autoStop: number
}

export interface RadioConfig {
  access: RadioAccess
  frequencies: RadioFrequencies
  device: RadioDevice
  alerts: RadioAlerts
}

const DEV_BANDS: ReservedBand[] = [
  {
    frequency: 155.475,
    label: 'LSPD',
    job: 'police',
    preset: 1,
    channels: ['Dispatch', 'Patrol', 'Tactical', 'Detectives'],
  },
  {
    frequency: 155.34,
    label: 'EMS',
    job: 'ems',
    preset: 2,
    channels: ['Dispatch', 'Field', 'Hospital'],
  },
]

/** What the device assumes until the game sends its config/device.lua. */
const DEVICE_DEFAULTS: RadioDevice = {
  volume: { default: 70, step: 5 },
  sounds: { micClicks: true, keyTones: true, reception: true },
  boot: { enabled: true },
  display: { clock24h: true, noticeDuration: 2200, toastDuration: 3200, alertDuration: 6000 },
  scan: { dwell: 2500 },
}

/**
 * In the browser, `?access=restricted&allowed=0` and `?job=police` simulate
 * the server's answer; in the game everything comes from the ready call.
 */
const initial = (): RadioConfig => {
  const frequencies: RadioFrequencies = {
    range: { min: 100, max: 999.995 },
    step: 0.005,
    open: { mode: 'single', count: 1 },
    reserved: import.meta.env.DEV ? DEV_BANDS : [],
  }

  if (!import.meta.env.DEV) {
    return {
      access: { mode: 'everyone', allowed: false, job: null, presets: [] },
      frequencies,
      device: DEVICE_DEFAULTS,
      alerts: { enabled: true, autoStop: 0 },
    }
  }

  const params = new URLSearchParams(window.location.search)
  const mode: AccessMode = params.get('access') === 'restricted' ? 'restricted' : 'everyone'
  const job = params.get('job')
  const presets = DEV_BANDS.filter((band) => band.preset !== null).map((band) => ({
    index: band.preset!,
    label: band.label,
    frequency: band.frequency,
    allowed: band.job === job,
  }))

  return {
    access: { mode, allowed: params.get('allowed') !== '0', job, presets },
    frequencies,
    device: DEVICE_DEFAULTS,
    alerts: { enabled: params.get('alerts') !== '0', autoStop: 0 },
  }
}

const state = $state<RadioConfig>(initial())

/**
 * The server's choices, answered to the ready call and pushed again when
 * they change. The interface reads them and never decides on its own.
 */
export const config = {
  get state(): RadioConfig {
    return state
  },

  get access(): RadioAccess {
    return state.access
  },

  get frequencies(): RadioFrequencies {
    return state.frequencies
  },

  get device(): RadioDevice {
    return state.device
  },

  get alerts(): RadioAlerts {
    return state.alerts
  },

  /** Whether the player may raise an alert from where they are tuned. */
  canAlert(frequency: number | null): boolean {
    if (!state.alerts.enabled || frequency === null) {
      return false
    }

    const band = this.band(frequency)

    return band !== null && band.job === state.access.job
  },

  /** Whether the player may use the device at all. */
  get allowed(): boolean {
    return state.access.mode === 'everyone' || state.access.allowed
  },

  /** Whether the player belongs to a service that owns a reserved band. */
  get hasService(): boolean {
    const job = state.access.job

    return job !== null && state.frequencies.reserved.some((band) => band.job === job)
  },

  /**
   * Whether channels exist for this player: always when open frequencies
   * carry channels, otherwise only on the bands of their own service.
   */
  get hasChannels(): boolean {
    const { mode, count } = state.frequencies.open

    return (mode === 'channels' && count > 1) || this.hasService
  },

  /** The reserved band on a frequency, if any. */
  band(frequency: number): ReservedBand | null {
    return state.frequencies.reserved.find((band) => band.frequency === frequency) ?? null
  },

  /** Whether the player may tune a frequency. */
  canTune(frequency: number): boolean {
    if (!this.allowed) {
      return false
    }

    const band = this.band(frequency)

    return band === null || band.job === state.access.job
  },

  /** The channels a frequency carries, named. Empty when the frequency is the channel. */
  channels(frequency: number): string[] {
    const band = this.band(frequency)

    if (band) {
      return band.channels
    }

    const { mode, count } = state.frequencies.open

    return mode === 'channels' && count > 1
      ? Array.from({ length: count }, (_, index) => `CH ${index + 1}`)
      : []
  },

  preset(index: number): RadioPreset | null {
    return state.access.presets.find((preset) => preset.index === index) ?? null
  },

  /** Snaps a frequency to the grid, or refuses it. */
  normalize(value: number): number | null {
    if (!Number.isFinite(value)) {
      return null
    }

    const { range, step } = state.frequencies
    const frequency = Math.round(Math.round(value / step) * step * 1000) / 1000

    return frequency >= range.min && frequency <= range.max ? frequency : null
  },

  patch(changes: Partial<RadioConfig>): void {
    if (changes.access) {
      state.access = { ...state.access, ...changes.access }
    }

    if (changes.frequencies) {
      state.frequencies = { ...state.frequencies, ...changes.frequencies }
    }

    if (changes.alerts) {
      state.alerts = { ...state.alerts, ...changes.alerts }
    }

    if (changes.device) {
      state.device = {
        volume: { ...state.device.volume, ...changes.device.volume },
        sounds: { ...state.device.sounds, ...changes.device.sounds },
        boot: { ...state.device.boot, ...changes.device.boot },
        display: { ...state.device.display, ...changes.device.display },
        scan: { ...state.device.scan, ...changes.device.scan },
      }
    }
  },

  /** Development only: pretend the player holds a job. */
  setJob(job: string | null): void {
    state.access.job = job
    state.access.presets = state.access.presets.map((preset) => ({
      ...preset,
      allowed: this.band(preset.frequency)?.job === job,
    }))
  },
}
