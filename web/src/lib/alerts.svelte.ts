export interface AlertInfo {
  from: string
  job: string | null
  label: string
  frequency: number
  channel: number
  channelLabel: string | null
  /** Unix seconds when the server raised it. */
  at: number
  /** Milliseconds when this device received it. */
  receivedAt: number
}

let active = $state<AlertInfo | null>(null)
let loop: HTMLAudioElement | null = null
let stopTimer: ReturnType<typeof setTimeout> | null = null

const LOOP_VOLUME = 0.7

const startLoop = (): void => {
  try {
    if (!loop) {
      loop = new Audio(`${import.meta.env.BASE_URL}sounds/alert_loop.wav`)
      loop.loop = true
    }

    loop.volume = LOOP_VOLUME
    loop.currentTime = 0
    void loop.play().catch(() => undefined)
  } catch {
    return
  }
}

const stopLoop = (): void => {
  if (loop) {
    loop.pause()
    loop.currentTime = 0
  }
}

/**
 * The emergency alert ringing on this device. It rings whether the radio
 * is open or in the pocket, and only STOP ends it, or the configured auto
 * stop. A newer alert replaces the ringing one.
 */
export const alerts = {
  get active(): AlertInfo | null {
    return active
  },

  get ringing(): boolean {
    return active !== null
  },

  start(info: Omit<AlertInfo, 'receivedAt'>, autoStopSeconds = 0): void {
    active = { ...info, receivedAt: Date.now() }
    startLoop()

    if (stopTimer) {
      clearTimeout(stopTimer)
      stopTimer = null
    }

    if (autoStopSeconds > 0) {
      stopTimer = setTimeout(() => alerts.stop(), autoStopSeconds * 1000)
    }
  },

  stop(): void {
    active = null
    stopLoop()

    if (stopTimer) {
      clearTimeout(stopTimer)
      stopTimer = null
    }
  },
}
