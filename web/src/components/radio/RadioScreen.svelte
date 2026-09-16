<script lang="ts">
  import { onMount } from 'svelte'
  import { Lock } from '@lucide/svelte'
  import { m } from '@/lib/i18n.svelte'
  import { config } from '@/lib/config.svelte'
  import type { RadioState } from '@/lib/radio.svelte'
  import { ui } from '@/lib/ui.svelte'

  let { device }: { device: RadioState } = $props()

  const SIGNAL_BARS = [1, 2, 3, 4]
  const VOLUME_BARS = [1, 2, 3, 4, 5, 6, 7, 8]
  const CLOCK_TICK_MS = 15000

  const locked = $derived(!config.allowed)
  const tuned = $derived(device.tuned)
  const live = $derived(device.transmitting ? 'TX' : device.receiving ? 'RX' : null)
  const volumeBars = $derived(Math.round((device.volume / 100) * VOLUME_BARS.length))
  const batteryLevel = $derived(Math.max(0, Math.min(100, device.battery)))
  const title = $derived(tuned ? (tuned.label ?? tuned.frequency.toFixed(3)) : 'VX-8')
  const hasChannels = $derived(tuned ? config.channels(tuned.frequency).length > 1 : false)

  const readClock = (): string =>
    new Date().toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
      hour12: !config.device.display.clock24h,
    })

  let clock = $state(readClock())

  onMount(() => {
    const timer = setInterval(() => (clock = readClock()), CLOCK_TICK_MS)

    return () => clearInterval(timer)
  })
</script>

<div
  class="radio-screen relative flex h-full w-full flex-col justify-between px-[6%] py-[5%] font-mono text-[var(--sk-accent-text)] transition-opacity duration-500"
  class:opacity-0={!device.powered}
>
  <div class="flex items-center justify-between text-[0.52em] uppercase tracking-[0.16em]">
    <span class="flex min-w-0 items-center gap-[0.55em]">
      <span class="flex shrink-0 items-end gap-[0.12em]" aria-hidden="true">
        {#each SIGNAL_BARS as bar (bar)}
          <span
            class="w-[0.22em] rounded-[0.05em] transition-colors duration-300 {bar <=
              device.signal &&
            !locked &&
            tuned
              ? 'bg-current'
              : 'bg-current/20'}"
            style:height="{0.35 + bar * 0.22}em"
          ></span>
        {/each}
      </span>
      <span class="truncate opacity-85">{title}</span>
    </span>

    {#if locked}
      <span
        class="rounded-[0.3em] bg-white/[0.06] px-[0.5em] py-[0.12em] font-semibold text-white/60"
      >
        LOCK
      </span>
    {:else if live}
      <span
        class="rounded-[0.3em] px-[0.5em] py-[0.12em] font-semibold tracking-[0.14em] {live === 'TX'
          ? 'bg-[var(--sk-accent)] text-[var(--sk-accent-ink)] shadow-glow'
          : 'bg-white/10'}"
      >
        {live}
      </span>
    {:else if device.scanning}
      <span class="animate-pulse font-semibold tracking-[0.14em] opacity-80">SCAN</span>
    {:else}
      <span class="opacity-70">{clock}</span>
    {/if}
  </div>

  {#if locked}
    <div class="flex flex-col items-center gap-[0.3em] text-center">
      <span
        class="flex items-center gap-[0.4em] text-[0.62em] font-semibold uppercase tracking-[0.22em]"
      >
        <Lock class="h-[1.1em] w-[1.1em]" />
        {m.radio_locked_title()}
      </span>
      <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.18em] opacity-55">
        {m.radio_locked_subtitle()}
      </span>
    </div>
  {:else if tuned}
    <div class="flex flex-col items-center gap-[0.25em] text-center">
      <span class="flex items-baseline justify-center">
        <span class="text-[1.45em] font-semibold leading-none tracking-[0.02em]">
          {tuned.frequency.toFixed(3)}
        </span>
        <span class="ml-[0.3em] text-[0.55em] font-medium opacity-70">MHz</span>
      </span>
      <span
        class="flex items-center gap-[0.6em] whitespace-nowrap text-[0.4em] uppercase tracking-[0.18em] opacity-65"
      >
        {#if tuned.channelLabel}
          <span>{tuned.channelLabel}</span>
        {/if}
        {#if hasChannels}
          <span class="opacity-70">{m.radio_channel_hint()}</span>
        {/if}
      </span>
    </div>
  {:else}
    <div class="flex flex-col items-center gap-[0.3em] text-center">
      <span class="text-[0.95em] font-semibold leading-none tracking-[0.12em] opacity-40">
        ---.---
      </span>
      <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.18em] opacity-60">
        {m.radio_home_hint()}
      </span>
    </div>
  {/if}

  <div class="flex items-center justify-between text-[0.5em] tracking-[0.12em] opacity-75">
    <span class="flex items-center gap-[0.5em]">
      <span class="uppercase">Vol</span>
      <span class="flex items-center gap-[0.14em]" aria-hidden="true">
        {#each VOLUME_BARS as bar (bar)}
          <span
            class="h-[0.7em] w-[0.18em] rounded-[0.04em] {bar <= volumeBars
              ? 'bg-current'
              : 'bg-current/20'}"
          ></span>
        {/each}
      </span>
    </span>

    <span class="flex items-center gap-[0.4em]">
      <span>{batteryLevel}%</span>
      <span
        class="relative flex h-[0.85em] w-[1.6em] items-center rounded-[0.15em] border border-current/70 p-[0.1em]"
        aria-hidden="true"
      >
        <span
          class="h-full rounded-[0.06em] {batteryLevel <= 20
            ? 'animate-pulse bg-[var(--sk-accent)]'
            : 'bg-current'}"
          style:width="{batteryLevel}%"
        ></span>
        <span
          class="absolute -right-[0.22em] top-1/2 h-[0.35em] w-[0.14em] -translate-y-1/2 rounded-r-[0.05em] bg-current/70"
        ></span>
      </span>
    </span>
  </div>

  {#if ui.toast}
    <div
      class="absolute inset-x-[6%] bottom-[22%] flex justify-center text-[0.42em] font-semibold uppercase tracking-[0.18em]"
    >
      <span
        class="rounded-[0.35em] px-[0.8em] py-[0.25em] {ui.toast.kind === 'error'
          ? 'bg-white/10 text-white/80'
          : ui.toast.kind === 'alert'
            ? 'animate-pulse bg-[var(--sk-accent)] text-[var(--sk-accent-ink)] shadow-glow'
            : 'bg-[var(--sk-accent-tint)] text-[var(--sk-accent-text)]'}"
      >
        {ui.toast.text}
      </span>
    </div>
  {/if}

  <div class="radio-screen__glass pointer-events-none absolute inset-0"></div>
</div>

<style>
  .radio-screen {
    background:
      radial-gradient(120% 90% at 50% 0%, rgba(108, 182, 246, 0.1), transparent 60%), rgb(4, 6, 9);
    text-shadow: 0 0 0.6em rgba(108, 182, 246, 0.45);
  }

  /**
   * A faint line pattern and a vignette, so the display reads as glass over
   * an LCD rather than a flat box.
   */
  .radio-screen__glass {
    background:
      repeating-linear-gradient(
        0deg,
        rgba(255, 255, 255, 0.025) 0,
        rgba(255, 255, 255, 0.025) 1px,
        transparent 1px,
        transparent 3px
      ),
      radial-gradient(90% 80% at 50% 50%, transparent 55%, rgba(0, 0, 0, 0.45) 100%);
  }
</style>
