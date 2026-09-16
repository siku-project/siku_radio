<script lang="ts" module>
  import { m } from '@/lib/i18n.svelte'
  import type { DeviceSettings } from '@/lib/ui.svelte'

  export const SETTINGS: { key: keyof DeviceSettings; label: () => string }[] = [
    { key: 'micClicks', label: () => m.settings_mic_clicks() },
    { key: 'keyTones', label: () => m.settings_key_tones() },
    { key: 'sounds', label: () => m.settings_sounds() },
  ]
</script>

<script lang="ts">
  import { ui } from '@/lib/ui.svelte'
  import ListScreen from './ListScreen.svelte'

  const items = $derived(
    SETTINGS.map((entry) => ({
      id: entry.key,
      label: entry.label(),
      value: ui.settings[entry.key] ? m.setting_on() : m.setting_off(),
      active: ui.settings[entry.key],
    })),
  )

  const pick = (index: number): void => {
    ui.setCursor('settings', index)
    ui.toggleSetting(SETTINGS[index]!.key)
  }
</script>

<ListScreen title={m.menu_settings()} {items} cursor={ui.cursor('settings')} onPick={pick} />
