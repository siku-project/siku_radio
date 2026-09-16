<script lang="ts">
  import { m } from '@/lib/i18n.svelte'
  import { config } from '@/lib/config.svelte'
  import { radio } from '@/lib/radio.svelte'
  import pkg from '../../../../package.json'
  import PanelScreen from './PanelScreen.svelte'

  const rows = $derived([
    { label: m.info_model(), value: 'VORTEX VX-8' },
    { label: m.info_firmware(), value: `v${pkg.version}` },
    { label: m.info_job(), value: config.access.job?.toUpperCase() ?? m.info_none() },
    { label: m.info_battery(), value: `${radio.state.battery}%` },
  ])
</script>

<PanelScreen title={m.menu_info()}>
  <div class="flex w-full flex-col gap-[0.15em] text-[0.48em] uppercase tracking-[0.14em]">
    {#each rows as row (row.label)}
      <div class="flex items-center justify-between gap-[1em]">
        <span class="opacity-55">{row.label}</span>
        <span class="text-[var(--sk-accent-text)]">{row.value}</span>
      </div>
    {/each}
  </div>
</PanelScreen>
