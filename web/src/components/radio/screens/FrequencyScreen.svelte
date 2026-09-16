<script lang="ts">
  import { m } from '@/lib/i18n.svelte'
  import { config } from '@/lib/config.svelte'
  import { radio } from '@/lib/radio.svelte'
  import PanelScreen from './PanelScreen.svelte'

  /** The typed digits laid out as a frequency, the missing ones as dashes. */
  const display = $derived.by(() => {
    const typed = radio.entry.padEnd(6, '-')

    return `${typed.slice(0, 3)}.${typed.slice(3)}`
  })

  const current = $derived(radio.state.tuned?.frequency.toFixed(3) ?? null)
  const typing = $derived(radio.entry.length > 0)
  const range = $derived(config.frequencies.range)
</script>

<PanelScreen title={m.menu_frequency()}>
  <span class="flex items-baseline gap-[0.3em]">
    <span
      class="text-[1.2em] font-semibold leading-none tracking-[0.06em] {typing
        ? ''
        : current
          ? 'opacity-90'
          : 'opacity-40'}"
    >
      {typing ? display : (current ?? '---.---')}
    </span>
    <span class="text-[0.5em] opacity-70">MHz</span>
  </span>
  <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.16em] opacity-50">
    {typing
      ? m.frequency_hint()
      : m.frequency_range({ min: range.min.toFixed(3), max: range.max.toFixed(3) })}
  </span>
</PanelScreen>
