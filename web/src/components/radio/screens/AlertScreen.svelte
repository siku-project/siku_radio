<script lang="ts">
  import { onMount } from 'svelte'
  import { Siren } from '@lucide/svelte'
  import { m } from '@/lib/i18n.svelte'
  import type { AlertInfo } from '@/lib/alerts.svelte'

  let { alert, onStop }: { alert: AlertInfo; onStop: () => void } = $props()

  const TICK_MS = 1000

  let now = $state(Date.now())

  const elapsed = $derived.by(() => {
    const seconds = Math.max(0, Math.floor((now - alert.receivedAt) / 1000))
    const minutes = Math.floor(seconds / 60)

    return `${String(minutes).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`
  })

  const where = $derived(
    alert.channelLabel ? `${alert.label} · ${alert.channelLabel}` : alert.label,
  )

  onMount(() => {
    const timer = setInterval(() => (now = Date.now()), TICK_MS)

    return () => clearInterval(timer)
  })
</script>

<div
  class="alert-screen relative flex h-full w-full flex-col justify-between px-[6%] py-[4.5%] font-mono text-[var(--sk-accent-text)]"
>
  <div
    class="flex items-center justify-between text-[0.52em] font-semibold uppercase tracking-[0.2em]"
  >
    <span class="flex items-center gap-[0.4em]">
      <Siren class="h-[1.2em] w-[1.2em] animate-pulse" />
      {m.alert_title()}
    </span>
    <span class="opacity-70">{elapsed}</span>
  </div>

  <div class="flex flex-col items-center gap-[0.15em] text-center">
    <span class="text-[0.7em] font-semibold uppercase tracking-[0.12em]">{alert.from}</span>
    <span class="whitespace-nowrap text-[0.42em] uppercase tracking-[0.16em] opacity-70">
      {where} · {alert.frequency.toFixed(3)}
    </span>
  </div>

  <div class="flex items-center justify-between">
    <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.16em] opacity-50">
      {m.alert_hint()}
    </span>
    <button
      type="button"
      class="pointer-events-auto rounded-[0.35em] bg-[var(--sk-accent)] px-[1em] py-[0.25em] text-[0.55em] font-bold uppercase tracking-[0.22em] text-[var(--sk-accent-ink)] shadow-glow transition-transform active:scale-95"
      onclick={onStop}
    >
      {m.alert_stop()}
    </button>
  </div>

  <div class="alert-screen__flash pointer-events-none absolute inset-0"></div>
</div>

<style>
  .alert-screen {
    background:
      radial-gradient(120% 90% at 50% 0%, rgba(108, 182, 246, 0.18), transparent 60%), rgb(4, 6, 9);
    text-shadow: 0 0 0.6em rgba(108, 182, 246, 0.55);
  }

  .alert-screen__flash {
    background: rgba(108, 182, 246, 0.12);
    animation: flash 1.1s ease-in-out infinite;
  }

  @keyframes flash {
    0%,
    100% {
      opacity: 0;
    }
    50% {
      opacity: 1;
    }
  }
</style>
