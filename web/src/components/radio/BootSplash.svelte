<script lang="ts">
  import { onMount } from 'svelte'

  let { onDone }: { onDone: () => void } = $props()

  type Phase = 'flash' | 'logo' | 'out'

  const FLASH_MS = 420
  const LOGO_MS = 1900
  const OUT_MS = 380

  let phase = $state<Phase>('flash')

  onMount(() => {
    const timers = [
      setTimeout(() => (phase = 'logo'), FLASH_MS),
      setTimeout(() => (phase = 'out'), FLASH_MS + LOGO_MS),
      setTimeout(onDone, FLASH_MS + LOGO_MS + OUT_MS),
    ]

    return () => timers.forEach(clearTimeout)
  })
</script>

<div class="boot absolute inset-0 overflow-hidden font-mono" data-phase={phase}>
  <div class="boot__beam"></div>

  <div class="boot__logo flex h-full w-full flex-col items-center justify-center">
    <span class="boot__brand">VORTEX</span>
    <span class="boot__model">VX-8 · TACTICAL COMMUNICATIONS</span>
    <span class="boot__bar"><span class="boot__fill"></span></span>
  </div>
</div>

<style>
  .boot {
    background: rgba(3, 4, 6, 1);
    color: var(--sk-accent-text);
  }

  .boot__beam {
    position: absolute;
    left: 50%;
    top: 50%;
    width: 0;
    height: 2px;
    background: rgba(226, 240, 252, 0.95);
    box-shadow:
      0 0 0.6em rgba(226, 240, 252, 0.9),
      0 0 1.6em rgba(108, 182, 246, 0.8);
    transform: translate(-50%, -50%);
    opacity: 0;
  }

  .boot[data-phase='flash'] .boot__beam {
    animation: beam 420ms cubic-bezier(0.2, 0.9, 0.3, 1) forwards;
  }

  .boot__logo {
    opacity: 0;
    gap: 0.35em;
  }

  .boot[data-phase='logo'] .boot__logo {
    opacity: 1;
  }

  .boot[data-phase='out'] .boot__logo {
    animation: out 380ms ease-in forwards;
  }

  .boot__brand {
    font-size: 1.35em;
    font-weight: 700;
    letter-spacing: 0.18em;
    text-shadow:
      0 0 0.5em rgba(108, 182, 246, 0.7),
      0 0 1.4em rgba(108, 182, 246, 0.35);
  }

  .boot[data-phase='logo'] .boot__brand {
    animation: brand 900ms cubic-bezier(0.16, 1, 0.3, 1) both;
  }

  .boot__model {
    font-size: 0.36em;
    letter-spacing: 0.2em;
    white-space: nowrap;
    text-align: center;
    opacity: 0.65;
  }

  .boot[data-phase='logo'] .boot__model {
    animation: rise 700ms 350ms cubic-bezier(0.16, 1, 0.3, 1) both;
  }

  .boot__bar {
    margin-top: 0.4em;
    width: 46%;
    height: 0.12em;
    overflow: hidden;
    border-radius: 9999px;
    background: rgba(255, 255, 255, 0.1);
  }

  .boot__fill {
    display: block;
    height: 100%;
    width: 0;
    border-radius: inherit;
    background: var(--sk-accent);
    box-shadow: 0 0 0.6em var(--sk-accent-glow);
  }

  .boot[data-phase='logo'] .boot__fill {
    animation: fill 1150ms 550ms cubic-bezier(0.65, 0, 0.35, 1) forwards;
  }

  @keyframes beam {
    0% {
      width: 0;
      height: 2px;
      opacity: 0;
    }
    25% {
      width: 100%;
      height: 2px;
      opacity: 1;
    }
    70% {
      width: 100%;
      height: 100%;
      opacity: 0.9;
    }
    100% {
      width: 100%;
      height: 100%;
      opacity: 0;
    }
  }

  @keyframes brand {
    0% {
      opacity: 0;
      letter-spacing: 0.7em;
      transform: scale(1.12);
      filter: blur(3px);
    }
    100% {
      opacity: 1;
      letter-spacing: 0.18em;
      transform: scale(1);
      filter: blur(0);
    }
  }

  @keyframes rise {
    0% {
      opacity: 0;
      transform: translateY(0.6em);
    }
    100% {
      opacity: 0.65;
      transform: translateY(0);
    }
  }

  @keyframes fill {
    0% {
      width: 0;
    }
    100% {
      width: 100%;
    }
  }

  @keyframes out {
    0% {
      opacity: 1;
      transform: scale(1);
      filter: blur(0);
    }
    100% {
      opacity: 0;
      transform: scale(0.94);
      filter: blur(2px);
    }
  }
</style>
