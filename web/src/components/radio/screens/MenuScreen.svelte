<script lang="ts">
  import { m } from '@/lib/i18n.svelte'
  import { menuEntries } from '@/lib/menu'
  import { ui } from '@/lib/ui.svelte'
  import ListScreen from './ListScreen.svelte'

  let { onPick }: { onPick: (index: number) => void } = $props()

  const items = $derived(
    menuEntries().map((entry) => ({ id: entry.id, label: entry.label(), icon: entry.icon })),
  )
</script>

<ListScreen title={m.menu_title()} {items} cursor={ui.cursor('menu')} {onPick} />
