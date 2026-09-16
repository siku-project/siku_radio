<script lang="ts">
  import { m } from '@/lib/i18n.svelte'
  import { actions } from '@/lib/actions'
  import { config } from '@/lib/config.svelte'
  import { radio } from '@/lib/radio.svelte'
  import { ui } from '@/lib/ui.svelte'
  import ListScreen from './ListScreen.svelte'
  import PanelScreen from './PanelScreen.svelte'

  const tuned = $derived(radio.state.tuned)
  const channels = $derived(tuned ? config.channels(tuned.frequency) : [])

  const items = $derived(
    channels.map((label, index) => ({
      id: `${index + 1}`,
      label,
      value: `${index + 1}`,
      active: tuned?.channel === index + 1,
    })),
  )

  const pick = (index: number): void => {
    if (!tuned) {
      return
    }

    ui.setCursor('channels', index)
    actions.tune(tuned.frequency, index + 1)
    ui.home()
  }
</script>

{#if !tuned}
  <PanelScreen title={m.menu_channels()}>
    <span class="text-[0.55em] uppercase tracking-[0.18em] opacity-70">{m.channels_empty()}</span>
    <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.16em] opacity-45">
      {m.channels_empty_hint()}
    </span>
  </PanelScreen>
{:else if items.length > 0}
  <ListScreen
    title={tuned.label ?? m.menu_channels()}
    {items}
    cursor={ui.cursor('channels')}
    onPick={pick}
  />
{:else}
  <PanelScreen title={m.menu_channels()}>
    <span class="text-[0.55em] uppercase tracking-[0.18em] opacity-70">{m.channels_single()}</span>
    <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.16em] opacity-45">
      {m.channels_single_hint()}
    </span>
  </PanelScreen>
{/if}
