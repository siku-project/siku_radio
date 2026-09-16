<script lang="ts">
  import { m } from '@/lib/i18n.svelte'
  import { menuEntries } from '@/lib/menu'
  import { ui } from '@/lib/ui.svelte'
  import ListScreen from './ListScreen.svelte'

  const entries = $derived(menuEntries())
  const items = $derived(
    entries.map((entry) => ({ id: entry.screen, label: entry.label(), icon: entry.icon })),
  )

  const pick = (index: number): void => {
    ui.setCursor('menu', index)
    ui.push(entries[index]!.screen)
  }
</script>

<ListScreen title={m.menu_title()} {items} cursor={ui.cursor('menu')} onPick={pick} />
