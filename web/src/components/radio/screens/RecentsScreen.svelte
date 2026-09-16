<script lang="ts">
  import { m } from '@/lib/i18n.svelte'
  import { actions } from '@/lib/actions'
  import { config } from '@/lib/config.svelte'
  import { radio } from '@/lib/radio.svelte'
  import { ui } from '@/lib/ui.svelte'
  import ListScreen from './ListScreen.svelte'
  import PanelScreen from './PanelScreen.svelte'

  const items = $derived(
    radio.recents.map((frequency) => ({
      id: frequency.toFixed(3),
      label: config.band(frequency)?.label ?? frequency.toFixed(3),
      value: config.band(frequency) ? frequency.toFixed(3) : undefined,
      active: radio.state.tuned?.frequency === frequency,
    })),
  )

  const pick = (index: number): void => {
    const frequency = radio.recents[index]

    if (frequency === undefined) {
      return
    }

    ui.setCursor('recents', index)
    actions.tune(frequency)
    ui.home()
  }
</script>

{#if items.length > 0}
  <ListScreen title={m.menu_recents()} {items} cursor={ui.cursor('recents')} onPick={pick} />
{:else}
  <PanelScreen title={m.menu_recents()}>
    <span class="text-[0.55em] uppercase tracking-[0.18em] opacity-70">{m.recents_empty()}</span>
    <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.16em] opacity-45">
      {m.recents_empty_hint()}
    </span>
  </PanelScreen>
{/if}
