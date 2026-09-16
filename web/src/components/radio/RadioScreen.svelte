<script lang="ts">
  import { onMount } from 'svelte'
  import { Lock, X } from '@lucide/svelte'
  import { m } from '@/lib/i18n.svelte'
  import { config } from '@/lib/config.svelte'
  import { channelTargets, quickTargets, type QuickTarget } from '@/lib/quick'
  import type { RadioState } from '@/lib/radio.svelte'
  import { ui } from '@/lib/ui.svelte'

  let {
    device,
    onTune,
    onLeave,
  }: {
    device: RadioState
    onTune: (target: QuickTarget) => void
    onLeave: () => void
  } = $props()

  const SIGNAL_BARS = [1, 2, 3, 4]
  const VOLUME_BARS = [1, 2, 3, 4, 5, 6, 7, 8]
  const CLOCK_TICK_MS = 15000

  const locked = $derived(!config.allowed)
  const tuned = $derived(device.tuned)
  const live = $derived(device.transmitting ? 'TX' : device.receiving ? 'RX' : null)
  const volumeBars = $derived(Math.round((device.volume / 100) * VOLUME_BARS.length))
  const batteryLevel = $derived(Math.max(0, Math.min(100, device.battery)))
  const title = $derived(tuned ? (tuned.label ?? tuned.frequency.toFixed(3)) : 'VX-8')

  /**
   * One row of chips: the channels of the band when it has some, otherwise
   * the places to go, the current one left out since it is already read above.
   */
  const channels = $derived(channelTargets())
  const targets = $derived(
    channels.length > 0 ? channels : quickTargets().filter((target) => !target.active),
  )

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
  {:else}
    <div class="flex flex-col items-center gap-[0.3em] text-center">
      {#if tuned}
        <span class="relative flex items-baseline justify-center">
          <span class="text-[1.35em] font-semibold leading-none tracking-[0.02em]">
            {tuned.frequency.toFixed(3)}
          </span>
          <span class="ml-[0.3em] text-[0.5em] font-medium opacity-70">MHz</span>
          <button
            type="button"
            class="radio-leave pointer-events-auto absolute left-full top-1/2 ml-[0.6em] flex h-[1.1em] w-[1.1em] -translate-y-1/2 items-center justify-center rounded-full text-[0.6em]"
            title={m.radio_leave()}
            aria-label={m.radio_leave()}
            onclick={onLeave}
          >
            <X class="h-[70%] w-[70%]" />
          </button>
        </span>
      {:else}
        <span class="text-[0.85em] font-semibold leading-none tracking-[0.12em] opacity-40">
          ---.---
        </span>
      {/if}

      {#if targets.length > 0}
        <div
          class="radio-chips pointer-events-auto flex max-w-full items-center gap-[0.35em] overflow-x-auto whitespace-nowrap px-[0.2em] text-[0.4em] uppercase tracking-[0.14em]"
        >
          {#each targets as target (target.key)}
            <button
              type="button"
              class="radio-chip shrink-0 rounded-[0.5em] border px-[0.7em] py-[0.2em] leading-none"
              class:radio-chip--active={target.active}
              disabled={target.active}
              onclick={() => onTune(target)}
              {@attach (node) => {
                if (target.active) {
                  node.scrollIntoView({ inline: 'center', block: 'nearest' })
                }
              }}
            >
              {target.label}
            </button>
          {/each}
        </div>
      {:else if !tuned}
        <span class="whitespace-nowrap text-[0.38em] uppercase tracking-[0.18em] opacity-60">
          {m.radio_home_hint()}
        </span>
      {/if}
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

  /** The chips sit above the glass so the pointer reaches them. */
  .radio-chips {
    position: relative;
    z-index: 1;
  }

  .radio-chip {
    border-color: rgba(158, 208, 251, 0.28);
    color: rgba(158, 208, 251, 0.75);
    text-shadow: none;
    transition:
      background 120ms ease,
      border-color 120ms ease,
      color 120ms ease;
  }

  .radio-chip:hover:not(:disabled) {
    border-color: rgba(158, 208, 251, 0.7);
    background: rgba(108, 182, 246, 0.14);
    color: var(--sk-accent-text);
  }

  .radio-chip--active {
    border-color: var(--sk-accent);
    background: var(--sk-accent);
    color: var(--sk-accent-ink);
    box-shadow: 0 0 0.6em rgba(108, 182, 246, 0.55);
  }

  .radio-leave {
    position: absolute;
    z-index: 1;
    color: rgba(158, 208, 251, 0.55);
    transition:
      background 120ms ease,
      color 120ms ease;
  }

  .radio-leave:hover {
    background: rgba(255, 255, 255, 0.1);
    color: white;
  }
</style>
