<script lang="ts">
  import { Lock, Siren } from '@lucide/svelte'
  import { m } from '@/lib/i18n.svelte'
  import { actions } from '@/lib/actions'
  import { config } from '@/lib/config.svelte'
  import { radio } from '@/lib/radio.svelte'
  import PanelScreen from './PanelScreen.svelte'

  const SENT_MS = 2200

  let { onSent }: { onSent: () => void } = $props()

  let sent = $state(false)

  const allowed = $derived(config.canAlert(radio.state.tuned?.frequency ?? null))

  export const confirm = (): void => {
    if (sent || !actions.alert()) {
      return
    }

    sent = true
    setTimeout(onSent, SENT_MS)
  }
</script>

<PanelScreen title={m.menu_emergency()}>
  {#if sent}
    <span
      class="flex items-center gap-[0.4em] text-[0.62em] font-semibold uppercase tracking-[0.22em] text-[var(--sk-accent)]"
    >
      <Siren class="h-[1.1em] w-[1.1em] animate-pulse" />
      {m.emergency_sent()}
    </span>
  {:else if !allowed}
    <span
      class="flex items-center gap-[0.4em] text-[0.55em] uppercase tracking-[0.18em] opacity-70"
    >
      <Lock class="h-[1.1em] w-[1.1em]" />
      {radio.state.tuned ? m.alert_refused_job() : m.emergency_untuned()}
    </span>
  {:else}
    <button
      type="button"
      class="pointer-events-auto flex items-center gap-[0.5em] rounded-[0.35em] border border-[var(--sk-accent-border)] bg-[var(--sk-accent-tint)] px-[0.9em] py-[0.3em] text-[0.6em] font-semibold uppercase tracking-[0.2em] text-[var(--sk-accent-text)] transition-colors duration-150 hover:bg-[var(--sk-accent)] hover:text-[var(--sk-accent-ink)]"
      onclick={confirm}
    >
      <Siren class="h-[1.1em] w-[1.1em]" />
      {m.emergency_confirm()}
    </button>
    <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.16em] opacity-50">
      {m.emergency_hint()}
    </span>
  {/if}
</PanelScreen>
