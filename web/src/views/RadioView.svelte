<script lang="ts">
  import { fade, fly } from 'svelte/transition'
  import BootSplash from '@/components/radio/BootSplash.svelte'
  import RadioFrame from '@/components/radio/RadioFrame.svelte'
  import RadioKeys, { type KeyPress } from '@/components/radio/RadioKeys.svelte'
  import RadioScreen from '@/components/radio/RadioScreen.svelte'
  import ChannelsScreen from '@/components/radio/screens/ChannelsScreen.svelte'
  import EmergencyScreen from '@/components/radio/screens/EmergencyScreen.svelte'
  import FrequencyScreen from '@/components/radio/screens/FrequencyScreen.svelte'
  import InfoScreen from '@/components/radio/screens/InfoScreen.svelte'
  import MenuScreen from '@/components/radio/screens/MenuScreen.svelte'
  import RecentsScreen from '@/components/radio/screens/RecentsScreen.svelte'
  import ScanScreen from '@/components/radio/screens/ScanScreen.svelte'
  import SettingsScreen, { SETTINGS } from '@/components/radio/screens/SettingsScreen.svelte'
  import VolumeScreen from '@/components/radio/screens/VolumeScreen.svelte'
  import { actions } from '@/lib/actions'
  import { m } from '@/lib/i18n.svelte'
  import { config } from '@/lib/config.svelte'
  import { menuEntries } from '@/lib/menu'
  import { alerts } from '@/lib/alerts.svelte'
  import AlertScreen from '@/components/radio/screens/AlertScreen.svelte'
  import { radio } from '@/lib/radio.svelte'
  import { play } from '@/lib/sounds'
  import { ui } from '@/lib/ui.svelte'

  const outlineKeys = import.meta.env.DEV && new URLSearchParams(window.location.search).has('keys')

  let emergency = $state<EmergencyScreen | null>(null)
  let scanTimer: ReturnType<typeof setInterval> | null = null

  const interactive = $derived(radio.state.visible && !radio.booting && config.allowed)

  const presetsAllowed = $derived(
    Object.fromEntries(config.access.presets.map((preset) => [preset.index, preset.allowed])),
  )

  const alertAllowed = $derived(config.canAlert(radio.state.tuned?.frequency ?? null))

  /** Off the air, from the menu, the cross on the display or Backspace. */
  const leaveFrequency = (): void => {
    if (!radio.state.tuned) {
      return
    }

    actions.leave()
    ui.notify(m.toast_left(), 'info')
    ui.home()
  }

  /** Opens a menu entry: its screen, or what it does when it has none. */
  const openEntry = (index: number): void => {
    const entry = menuEntries()[index]

    if (!entry) {
      return
    }

    ui.setCursor('menu', index)

    if (entry.screen) {
      ui.push(entry.screen)
      return
    }

    if (entry.id === 'leave') {
      leaveFrequency()
      return
    }

    entry.run?.()
  }

  /** Where the arrows go and what the dial picks, per screen. */
  const handleDial = (action: 'up' | 'down' | 'select'): void => {
    const screen = ui.current
    const direction = action === 'up' ? -1 : 1

    switch (screen) {
      case 'menu':
        if (action === 'select') {
          openEntry(ui.cursor('menu'))
        } else {
          ui.moveCursor('menu', direction, menuEntries().length)
        }
        break
      case 'channels': {
        const tuned = radio.state.tuned
        const count = tuned ? config.channels(tuned.frequency).length : 0

        if (action === 'select' && tuned && count > 0) {
          actions.tune(tuned.frequency, ui.cursor('channels') + 1)
          ui.home()
        } else if (action !== 'select') {
          ui.moveCursor('channels', direction, count)
        }
        break
      }
      case 'recents': {
        const frequency = radio.recents[ui.cursor('recents')]

        if (action === 'select' && frequency !== undefined) {
          actions.tune(frequency)
          ui.home()
        } else if (action !== 'select') {
          ui.moveCursor('recents', direction, radio.recents.length)
        }
        break
      }
      case 'settings':
        if (action === 'select') {
          ui.toggleSetting(SETTINGS[ui.cursor('settings')]!.key)
        } else {
          ui.moveCursor('settings', direction, SETTINGS.length)
        }
        break
      case 'scan':
        if (action === 'select') {
          toggleScan()
        }
        break
      case 'emergency':
        if (action === 'select') {
          emergency?.confirm()
        }
        break
      case 'frequency':
        if (action === 'select') {
          tuneEntry()
        }
        break
      case 'volume':
        if (action !== 'select') {
          actions.setVolume(radio.stepVolume(action === 'up' ? 1 : -1))
        }
        break
      default:
        if (action === 'select') {
          break
        }

        if (!actions.cycleChannel(action === 'up' ? 1 : -1)) {
          actions.setVolume(radio.stepVolume(action === 'up' ? 1 : -1))
        }
    }
  }

  /** Tunes what the keypad typed, then clears it. */
  const tuneEntry = (): void => {
    const frequency = radio.entryFrequency

    if (frequency === null) {
      return
    }

    actions.tune(frequency)
    radio.clearEntry()
    ui.home()
  }

  /** Walks the recents until something is received, or the key is pressed again. */
  const toggleScan = (): void => {
    if (radio.state.scanning) {
      stopScan()
      return
    }

    if (radio.recents.length < 2) {
      ui.notify(m.scan_empty(), 'error')
      play('error')
      return
    }

    radio.setScanning(true)
    scanTimer = setInterval(() => {
      if (radio.state.receiving || radio.state.transmitting) {
        return
      }

      const current = radio.recents.indexOf(radio.state.tuned?.frequency ?? -1)
      const next = radio.recents[(current + 1) % radio.recents.length]

      if (next !== undefined) {
        actions.tune(next)
      }
    }, config.device.scan.dwell)
  }

  const stopScan = (): void => {
    radio.setScanning(false)

    if (scanTimer) {
      clearInterval(scanTimer)
      scanTimer = null
    }
  }

  const handleKey = ({ action, digit }: KeyPress): void => {
    if (!interactive) {
      return
    }

    play('key')

    if (alerts.ringing) {
      if (action === 'select') {
        alerts.stop()
      }

      return
    }

    switch (action) {
      case 'menu':
        if (ui.current === 'menu') {
          ui.home()
        } else {
          ui.menu()
        }
        break
      case 'back':
        if (ui.current === 'frequency' && radio.entry.length > 0) {
          radio.clearEntry()
        } else if (ui.depth > 1) {
          ui.back()
        } else {
          actions.close()
        }
        break
      case 'scan':
        toggleScan()
        break
      case 'vfo':
        if (actions.cycleChannel(1)) {
          break
        }

        if (config.hasChannels) {
          ui.menu()
          ui.push('channels')
        } else {
          ui.notify(m.channels_single(), 'info')
        }
        break
      case 'p1':
      case 'p2':
      case 'p3': {
        const preset = config.preset(Number(action.slice(1)))

        if (preset?.allowed) {
          actions.tune(preset.frequency)
          ui.home()
        }
        break
      }
      case 'digit':
        if (digit) {
          if (ui.current !== 'frequency') {
            ui.menu()
            ui.push('frequency')
          }

          radio.typeDigit(digit)
        }
        break
      case 'star':
        if (ui.current === 'frequency') {
          radio.eraseDigit()
        } else if (ui.current === 'home') {
          leaveFrequency()
        }
        break
      case 'power':
        actions.powerOff()
        break
      case 'hash':
        if (ui.current === 'frequency') {
          tuneEntry()
        }
        break
      case 'alert':
        if (actions.alert()) {
          ui.notify(m.emergency_sent(), 'alert')
          ui.home()
        }
        break
      default:
        handleDial(action)
    }
  }

  const handleKeyboard = (event: KeyboardEvent): void => {
    if (!radio.state.visible) {
      return
    }

    if (event.key === 'Escape') {
      event.preventDefault()
      actions.close()
      return
    }

    if (!interactive) {
      return
    }

    if (/^\d$/.test(event.key)) {
      event.preventDefault()
      handleKey({ action: 'digit', digit: event.key })
      return
    }

    const mapped: Record<string, KeyPress> = {
      ArrowUp: { action: 'up' },
      ArrowDown: { action: 'down' },
      Enter: { action: ui.current === 'frequency' ? 'hash' : 'select' },
      Backspace: { action: 'star' },
      m: { action: 'menu' },
      p: { action: 'power' },
    }

    if (event.key === '+' || event.key === '-') {
      event.preventDefault()
      actions.setVolume(radio.stepVolume(event.key === '+' ? 1 : -1))
      return
    }

    const press = mapped[event.key]

    if (press) {
      event.preventDefault()
      handleKey(press)
    }
  }

  $effect(() => {
    if (!radio.state.visible) {
      stopScan()
    }
  })
</script>

<svelte:window onkeydown={handleKeyboard} />

{#if radio.state.visible}
  <div
    class="radio-view pointer-events-none fixed bottom-0 z-40"
    transition:fly={{ y: 120, duration: 380, opacity: 0 }}
  >
    <RadioFrame>
      {#snippet screen()}
        {#if radio.booting}
          <BootSplash onDone={() => radio.finishBoot()} />
        {:else}
          <div class="absolute inset-0" in:fade={{ duration: 450, delay: 80 }}>
            {#if alerts.active}
              <AlertScreen alert={alerts.active} onStop={() => alerts.stop()} />
            {:else}
              {#key ui.current}
                <div class="absolute inset-0" in:fade={{ duration: 160 }}>
                  {#if !config.allowed || ui.current === 'home'}
                    <RadioScreen
                      device={radio.state}
                      onTune={(target) => {
                        play('key')
                        actions.tune(target.frequency, target.channel)
                      }}
                      onLeave={() => {
                        play('key')
                        leaveFrequency()
                      }}
                    />
                  {:else if ui.current === 'menu'}
                    <MenuScreen onPick={openEntry} />
                  {:else if ui.current === 'frequency'}
                    <FrequencyScreen />
                  {:else if ui.current === 'channels'}
                    <ChannelsScreen />
                  {:else if ui.current === 'recents'}
                    <RecentsScreen />
                  {:else if ui.current === 'scan'}
                    <ScanScreen onToggle={toggleScan} />
                  {:else if ui.current === 'volume'}
                    <VolumeScreen
                      onAdjust={(direction) => actions.setVolume(radio.stepVolume(direction))}
                    />
                  {:else if ui.current === 'emergency'}
                    <EmergencyScreen bind:this={emergency} onSent={() => ui.home()} />
                  {:else if ui.current === 'settings'}
                    <SettingsScreen />
                  {:else if ui.current === 'info'}
                    <InfoScreen />
                  {/if}
                </div>
              {/key}
            {/if}
          </div>
        {/if}
      {/snippet}

      {#snippet keys()}
        {#if interactive}
          <RadioKeys
            onKey={handleKey}
            outline={outlineKeys}
            mouseNavigation={ui.mouseNavigation}
            {presetsAllowed}
            {alertAllowed}
          />
        {/if}
      {/snippet}
    </RadioFrame>
  </div>
{/if}

<style>
  /**
   * The render carries a dark halo around the device, about a fifth of its
   * width on the right. The view is shifted by that much so the device
   * itself, not the halo, sits at the margin.
   */
  .radio-view {
    --radio-height: 62vh;
    --radio-width: calc(var(--radio-height) * 1024 / 1536);

    right: calc(1.5rem - var(--radio-width) * 0.19);
    bottom: calc(-1 * var(--radio-height) * 0.01);
  }
</style>
