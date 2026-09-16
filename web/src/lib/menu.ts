import type { Component } from 'svelte'
import {
  History,
  Info,
  RadioTower,
  ScanSearch,
  Settings,
  Siren,
  SlidersHorizontal,
  Volume2,
} from '@lucide/svelte'
import { config } from '@/lib/config.svelte'
import { m } from '@/lib/i18n.svelte'
import type { Screen } from '@/lib/ui.svelte'

export interface MenuEntry {
  screen: Screen
  icon: Component
  label: () => string
}

/** The device menu as this server shows it: the alert entry only when alerts exist. */
export const menuEntries = (): MenuEntry[] =>
  MENU.filter((entry) => entry.screen !== 'emergency' || config.alerts.enabled)

/** The whole device menu, in the order the arrows walk it. */
export const MENU: MenuEntry[] = [
  { screen: 'frequency', icon: SlidersHorizontal, label: () => m.menu_frequency() },
  { screen: 'channels', icon: RadioTower, label: () => m.menu_channels() },
  { screen: 'recents', icon: History, label: () => m.menu_recents() },
  { screen: 'scan', icon: ScanSearch, label: () => m.menu_scan() },
  { screen: 'volume', icon: Volume2, label: () => m.menu_volume() },
  { screen: 'emergency', icon: Siren, label: () => m.menu_emergency() },
  { screen: 'settings', icon: Settings, label: () => m.menu_settings() },
  { screen: 'info', icon: Info, label: () => m.menu_info() },
]
