<script lang="ts">
  import { ChevronDown, ChevronUp } from '@lucide/svelte'

  export type KeyAction =
    | 'menu'
    | 'back'
    | 'scan'
    | 'vfo'
    | 'up'
    | 'down'
    | 'select'
    | 'p1'
    | 'p2'
    | 'p3'
    | 'digit'
    | 'star'
    | 'hash'
    | 'alert'
    | 'power'

  export interface KeyPress {
    action: KeyAction
    digit?: string
  }

  interface Hotspot extends KeyPress {
    label: string
    left: number
    top: number
    width: number
    height: number
    round?: boolean
  }

  let {
    onKey,
    outline = false,
    mouseNavigation = false,
    presetsAllowed = {},
    alertAllowed = false,
  }: {
    onKey: (press: KeyPress) => void
    outline?: boolean
    mouseNavigation?: boolean
    presetsAllowed?: Record<number, boolean>
    alertAllowed?: boolean
  } = $props()

  const KEY_W = 8.8
  const KEY_H = 3.3
  const COLUMNS = [32.2, 42.2, 52.3]
  const ROWS = [74.6, 78.1, 81.5, 85.0]

  /**
   * Every zone is a percentage of the frame render, measured on the image,
   * so the keys stay under the pointer whatever the device height. The dial
   * only answers to a press in its centre: up and down are the arrow keys.
   */
  const KEYS: Hotspot[] = [
    { action: 'menu', label: 'Menu', left: 31.6, top: 65.0, width: 9.6, height: 3.8 },
    { action: 'back', label: 'Back', left: 62.8, top: 65.0, width: 9.6, height: 3.8 },
    { action: 'scan', label: 'Scan', left: 31.6, top: 69.9, width: 9.6, height: 3.8 },
    { action: 'vfo', label: 'VFO / MR', left: 62.8, top: 69.9, width: 9.6, height: 3.8 },
    { action: 'p1', label: 'P1', left: 62.8, top: 74.6, width: 9.6, height: 3.6 },
    { action: 'p2', label: 'P2', left: 62.8, top: 78.5, width: 9.6, height: 3.6 },
    { action: 'p3', label: 'P3', left: 62.8, top: 82.6, width: 9.6, height: 3.6 },
    {
      action: 'alert',
      label: 'Emergency',
      left: 34.4,
      top: 34.9,
      width: 7.4,
      height: 3.1,
      round: true,
    },
    {
      action: 'select',
      label: 'Dial',
      left: 47.4,
      top: 67.0,
      width: 9.6,
      height: 6.4,
      round: true,
    },
    {
      action: 'power',
      label: 'Power',
      left: 47.6,
      top: 27.6,
      width: 11.4,
      height: 8.6,
      round: true,
    },
  ]

  const KEYPAD: Hotspot[] = [
    ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((digit, index) => ({
      action: 'digit' as const,
      digit,
      label: digit,
      left: COLUMNS[index % 3]!,
      top: ROWS[Math.floor(index / 3)]!,
      width: KEY_W,
      height: KEY_H,
    })),
    { action: 'star', label: '*', left: COLUMNS[0]!, top: ROWS[3]!, width: KEY_W, height: KEY_H },
    {
      action: 'digit',
      digit: '0',
      label: '0',
      left: COLUMNS[1]!,
      top: ROWS[3]!,
      width: KEY_W,
      height: KEY_H,
    },
    { action: 'hash', label: '#', left: COLUMNS[2]!, top: ROWS[3]!, width: KEY_W, height: KEY_H },
  ]

  /** Development only: the dial's up and down as visible buttons for the mouse. */
  const MOUSE_KEYS: Hotspot[] = [
    { action: 'up', label: 'Up', left: 48.4, top: 63.4, width: 7.6, height: 3.2, round: true },
    { action: 'down', label: 'Down', left: 48.4, top: 74.0, width: 7.6, height: 3.2, round: true },
  ]

  const presetIndex = (action: KeyAction): number | null =>
    action.startsWith('p') && action.length === 2 ? Number(action.slice(1)) : null

  const isLocked = (key: Hotspot): boolean => {
    if (key.action === 'alert') {
      return !alertAllowed
    }

    const index = presetIndex(key.action)

    return index !== null && presetsAllowed[index] !== true
  }
</script>

{#each [...KEYS, ...KEYPAD] as key (key.label)}
  <button
    type="button"
    class="radio-key pointer-events-auto absolute {key.round
      ? 'rounded-full'
      : 'rounded-[18%/40%]'}"
    class:radio-key--outline={outline}
    class:radio-key--locked={isLocked(key)}
    class:radio-key--alert={key.action === 'alert' && !isLocked(key)}
    style:left="{key.left}%"
    style:top="{key.top}%"
    style:width="{key.width}%"
    style:height="{key.height}%"
    aria-label={key.label}
    disabled={isLocked(key)}
    onclick={() => onKey({ action: key.action, digit: key.digit })}
  ></button>
{/each}

{#if mouseNavigation}
  {#each MOUSE_KEYS as key (key.action)}
    <button
      type="button"
      class="radio-key radio-key--visible pointer-events-auto absolute flex items-center justify-center rounded-full"
      style:left="{key.left}%"
      style:top="{key.top}%"
      style:width="{key.width}%"
      style:height="{key.height}%"
      aria-label={key.label}
      onclick={() => onKey({ action: key.action })}
    >
      {#if key.action === 'up'}
        <ChevronUp class="h-[70%] w-auto" />
      {:else}
        <ChevronDown class="h-[70%] w-auto" />
      {/if}
    </button>
  {/each}
{/if}

<style>
  .radio-key {
    background: transparent;
    transition: background 120ms ease;
  }

  .radio-key:hover:not(:disabled) {
    background: rgba(226, 240, 252, 0.08);
  }

  .radio-key:active:not(:disabled) {
    background: rgba(108, 182, 246, 0.22);
    box-shadow: 0 0 0.6em rgba(108, 182, 246, 0.35);
  }

  .radio-key:focus-visible {
    outline: none;
  }

  .radio-key--outline {
    outline: 1px dashed rgba(108, 182, 246, 0.6);
  }

  /** A preset the player has no job for: dimmed, and the pointer says so. */
  .radio-key--locked {
    cursor: not-allowed;
    background: rgba(0, 0, 0, 0.45);
  }

  /** The orange emergency button, live: it breathes so it reads as armed. */
  .radio-key--alert {
    box-shadow: 0 0 0.5em rgba(255, 140, 40, 0.55);
    animation: armed 2.4s ease-in-out infinite;
  }

  .radio-key--alert:hover {
    background: rgba(255, 140, 40, 0.25);
  }

  .radio-key--alert:active {
    background: rgba(255, 140, 40, 0.5);
    box-shadow: 0 0 1em rgba(255, 140, 40, 0.8);
  }

  @keyframes armed {
    0%,
    100% {
      box-shadow: 0 0 0.3em rgba(255, 140, 40, 0.25);
    }
    50% {
      box-shadow: 0 0 0.8em rgba(255, 140, 40, 0.7);
    }
  }

  .radio-key--visible {
    border: 1px solid rgba(108, 182, 246, 0.55);
    background: rgba(12, 22, 34, 0.85);
    color: var(--sk-accent-text);
    box-shadow: 0 0 0.6em rgba(108, 182, 246, 0.25);
  }

  .radio-key--visible:hover {
    background: rgba(108, 182, 246, 0.25);
  }
</style>
