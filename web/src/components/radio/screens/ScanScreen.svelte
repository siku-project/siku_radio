<script lang="ts">
  import { ScanSearch } from '@lucide/svelte'
  import { m } from '@/lib/i18n.svelte'
  import { radio } from '@/lib/radio.svelte'
  import PanelScreen from './PanelScreen.svelte'

  let { onToggle }: { onToggle: () => void } = $props()

  const empty = $derived(radio.recents.length < 2)
</script>

<PanelScreen title={m.menu_scan()}>
  <button
    type="button"
    class="pointer-events-auto flex items-center gap-[0.5em] rounded-[0.35em] px-[0.9em] py-[0.3em] text-[0.6em] font-semibold uppercase tracking-[0.2em] transition-colors duration-150 {radio
      .state.scanning
      ? 'bg-[var(--sk-accent)] text-[var(--sk-accent-ink)] shadow-glow'
      : 'bg-white/[0.08] text-white/70'}"
    onclick={onToggle}
  >
    <ScanSearch class="h-[1.1em] w-[1.1em] {radio.state.scanning ? 'animate-pulse' : ''}" />
    {radio.state.scanning ? m.scan_on() : m.scan_off()}
  </button>
  <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.16em] opacity-50">
    {empty ? m.scan_empty() : m.scan_hint()}
  </span>
</PanelScreen>
