import { ui } from '@/lib/ui.svelte'

export type Sound =
  'key' | 'tx_on' | 'tx_off' | 'rx_on' | 'rx_off' | 'boot' | 'alert' | 'error' | 'tune'

const VOLUMES: Record<Sound, number> = {
  key: 0.35,
  tx_on: 0.65,
  tx_off: 0.6,
  rx_on: 0.7,
  rx_off: 0.65,
  boot: 0.5,
  alert: 0.6,
  error: 0.45,
  tune: 0.4,
}

/** Which setting gates a sound. Unlisted sounds always play. */
const GATES: Partial<Record<Sound, keyof typeof ui.settings>> = {
  key: 'keyTones',
  tx_on: 'micClicks',
  tx_off: 'micClicks',
  rx_on: 'sounds',
  rx_off: 'sounds',
}

const cache = new Map<Sound, HTMLAudioElement>()

const load = (name: Sound): HTMLAudioElement => {
  let audio = cache.get(name)

  if (!audio) {
    audio = new Audio(`${import.meta.env.BASE_URL}sounds/${name}.wav`)
    audio.preload = 'auto'
    cache.set(name, audio)
  }

  return audio
}

/**
 * Plays a device sound, scaled by the radio volume, unless the player
 * switched that family off in the settings.
 */
export const play = (name: Sound, volume = 1): void => {
  const gate = GATES[name]

  if (gate && !ui.settings[gate]) {
    return
  }

  try {
    const audio = load(name)

    audio.currentTime = 0
    audio.volume = Math.max(0, Math.min(1, VOLUMES[name] * volume))
    void audio.play().catch(() => undefined)
  } catch {
    return
  }
}
