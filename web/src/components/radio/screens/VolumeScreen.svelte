<script lang="ts">
  import { Minus, Plus, Volume2 } from '@lucide/svelte'
  import { m } from '@/lib/i18n.svelte'
  import { radio } from '@/lib/radio.svelte'
  import PanelScreen from './PanelScreen.svelte'

  let { onAdjust }: { onAdjust: (direction: 1 | -1) => void } = $props()

  const BARS = Array.from({ length: 20 }, (_, index) => index + 1)

  const lit = $derived(Math.round((radio.state.volume / 100) * BARS.length))
</script>

<PanelScreen title={m.menu_volume()}>
  <span class="flex items-center gap-[0.5em] text-[0.7em] font-semibold">
    <Volume2 class="h-[1.1em] w-[1.1em]" />
    {radio.state.volume}%
  </span>
  <span class="flex items-center gap-[0.5em]">
    <button
      type="button"
      class="pointer-events-auto flex h-[1.4em] w-[1.4em] items-center justify-center rounded-full bg-white/[0.08] text-[0.6em] transition-colors hover:bg-white/15"
      aria-label="-"
      onclick={() => onAdjust(-1)}
    >
      <Minus class="h-[1em] w-[1em]" />
    </button>
    <span class="flex items-end gap-[0.1em]" aria-hidden="true">
      {#each BARS as bar (bar)}
        <span
          class="w-[0.3em] rounded-[0.05em] transition-colors duration-100 {bar <= lit
            ? 'bg-[var(--sk-accent-text)]'
            : 'bg-white/15'}"
          style:height="{0.4 + bar * 0.045}em"
        ></span>
      {/each}
    </span>
    <button
      type="button"
      class="pointer-events-auto flex h-[1.4em] w-[1.4em] items-center justify-center rounded-full bg-white/[0.08] text-[0.6em] transition-colors hover:bg-white/15"
      aria-label="+"
      onclick={() => onAdjust(1)}
    >
      <Plus class="h-[1em] w-[1em]" />
    </button>
  </span>
  <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.16em] opacity-50">
    {m.volume_hint()}
  </span>
</PanelScreen>
