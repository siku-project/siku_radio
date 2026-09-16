export type Screen =
  | 'home'
  | 'menu'
  | 'frequency'
  | 'channels'
  | 'recents'
  | 'scan'
  | 'volume'
  | 'emergency'
  | 'settings'
  | 'info'

export interface DeviceSettings {
  micClicks: boolean
  keyTones: boolean
  sounds: boolean
}

export interface Toast {
  text: string
  kind: 'info' | 'alert' | 'error'
}

const HOME: Screen = 'home'
const DEFAULT_NOTICE_MS = 2200

/** In the browser, `?screen=menu` opens the device on that screen. */
const initialStack = (): Screen[] => {
  if (!import.meta.env.DEV) {
    return [HOME]
  }

  const wanted = new URLSearchParams(window.location.search).get('screen')

  if (wanted === 'menu') {
    return [HOME, 'menu']
  }

  if (wanted && wanted !== HOME) {
    return [HOME, 'menu', wanted as Screen]
  }

  return [HOME]
}

let stack = $state<Screen[]>(initialStack())
const cursors = $state<Partial<Record<Screen, number>>>({})
const settings = $state<DeviceSettings>({ micClicks: true, keyTones: true, sounds: true })
const dev = $state({ mouseNavigation: false })
let toast = $state<Toast | null>(null)
let toastTimer: ReturnType<typeof setTimeout> | null = null
let noticeDuration = DEFAULT_NOTICE_MS

/** Where the display is, as a stack of screens, and what each one points at. */
export const ui = {
  get current(): Screen {
    return stack[stack.length - 1] ?? HOME
  },

  get depth(): number {
    return stack.length
  },

  get settings(): DeviceSettings {
    return settings
  },

  get toast(): Toast | null {
    return toast
  },

  /** Development only: whether the dial's up and down show as mouse buttons. */
  get mouseNavigation(): boolean {
    return import.meta.env.DEV && dev.mouseNavigation
  },

  setMouseNavigation(value: boolean): void {
    dev.mouseNavigation = value
  },

  /** What the game configured as the starting point of a session. */
  applyDefaults(
    sounds: Partial<{ micClicks: boolean; keyTones: boolean; reception: boolean }>,
    notice?: number,
  ): void {
    if (sounds.micClicks !== undefined) {
      settings.micClicks = sounds.micClicks
    }

    if (sounds.keyTones !== undefined) {
      settings.keyTones = sounds.keyTones
    }

    if (sounds.reception !== undefined) {
      settings.sounds = sounds.reception
    }

    if (notice !== undefined && notice > 0) {
      noticeDuration = notice
    }
  },

  cursor(screen: Screen): number {
    return cursors[screen] ?? 0
  },

  moveCursor(screen: Screen, direction: 1 | -1, count: number): number {
    if (count <= 0) {
      return 0
    }

    const next = Math.max(0, Math.min(count - 1, (cursors[screen] ?? 0) + direction))

    cursors[screen] = next

    return next
  },

  setCursor(screen: Screen, index: number): void {
    cursors[screen] = Math.max(0, index)
  },

  push(screen: Screen): void {
    if (this.current !== screen) {
      stack = [...stack, screen]
    }
  },

  back(): void {
    if (stack.length > 1) {
      stack = stack.slice(0, -1)
    }
  },

  /** Pops every screen above the menu, or opens it from home. */
  menu(): void {
    const index = stack.indexOf('menu')

    stack = index >= 0 ? stack.slice(0, index + 1) : [HOME, 'menu']
  },

  home(): void {
    stack = [HOME]
  },

  toggleSetting(key: keyof DeviceSettings): void {
    settings[key] = !settings[key]
  },

  /** Shows a short line on the display, replacing the previous one. */
  notify(text: string, kind: Toast['kind'] = 'info'): void {
    toast = { text, kind }

    if (toastTimer) {
      clearTimeout(toastTimer)
    }

    toastTimer = setTimeout(() => {
      toast = null
      toastTimer = null
    }, noticeDuration)
  },
}
