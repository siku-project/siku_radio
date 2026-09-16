import type { Component } from 'svelte'
import {
  History,
  Info,
  LogOut,
  Power,
  RadioTower,
  ScanSearch,
  Settings,
  Siren,
  SlidersHorizontal,
  Volume2,
} from '@lucide/svelte'
import { actions } from '@/lib/actions'
import { config } from '@/lib/config.svelte'
import { m } from '@/lib/i18n.svelte'
import { radio } from '@/lib/radio.svelte'
import type { Screen } from '@/lib/ui.svelte'

export type MenuId = Screen | 'leave' | 'power'

export interface MenuEntry {
  id: MenuId
  icon: Component
  label: () => string
  /** The screen the entry opens, or nothing when it acts on its own. */
  screen?: Screen
  /** What the entry does when it opens no screen. */
  run?: () => void
  /** Whether this player sees the entry right now. */
  shown?: () => boolean
}

/** The whole device menu, in the order the arrows walk it. */
export const MENU: MenuEntry[] = [
  {
    id: 'frequency',
    screen: 'frequency',
    icon: SlidersHorizontal,
    label: () => m.menu_frequency(),
  },
  {
    id: 'channels',
    screen: 'channels',
    icon: RadioTower,
    label: () => m.menu_channels(),
    shown: () => config.hasChannels,
  },
  { id: 'recents', screen: 'recents', icon: History, label: () => m.menu_recents() },
  { id: 'scan', screen: 'scan', icon: ScanSearch, label: () => m.menu_scan() },
  { id: 'volume', screen: 'volume', icon: Volume2, label: () => m.menu_volume() },
  {
    id: 'leave',
    icon: LogOut,
    label: () => m.menu_leave(),
    run: () => actions.leave(),
    shown: () => radio.state.tuned !== null,
  },
  {
    id: 'emergency',
    screen: 'emergency',
    icon: Siren,
    label: () => m.menu_emergency(),
    shown: () => config.alerts.enabled && config.hasService,
  },
  { id: 'settings', screen: 'settings', icon: Settings, label: () => m.menu_settings() },
  { id: 'info', screen: 'info', icon: Info, label: () => m.menu_info() },
  { id: 'power', icon: Power, label: () => m.menu_power(), run: () => actions.powerOff() },
]

/**
 * The device menu as this player sees it: a citizen never sees the alert,
 * nor the channels when a frequency is a channel; the frequency is only
 * left when one is tuned.
 */
export const menuEntries = (): MenuEntry[] => MENU.filter((entry) => entry.shown?.() ?? true)
