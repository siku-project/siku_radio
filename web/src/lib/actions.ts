import { config } from '@/lib/config.svelte'
import { m } from '@/lib/i18n.svelte'
import { inGame, sendNuiCallback } from '@/lib/nui'
import { radio } from '@/lib/radio.svelte'
import { play } from '@/lib/sounds'
import { ui } from '@/lib/ui.svelte'

/**
 * Everything the device asks the game for. In the game the request goes
 * through a NUI callback and the answer comes back as a state patch; in the
 * browser the same call plays the answer locally, so the interface behaves
 * the same on both sides.
 */
export const actions = {
  tune(frequency: number, channel = 1): void {
    const normalized = config.normalize(frequency)

    if (normalized === null) {
      ui.notify(m.radio_refused_invalid(), 'error')
      play('error')
      return
    }

    if (!config.canTune(normalized)) {
      ui.notify(config.band(normalized) ? m.radio_refused_job() : m.radio_refused_access(), 'error')
      play('error')
      return
    }

    if (inGame) {
      void sendNuiCallback('tune', { frequency: normalized, channel })
      return
    }

    const band = config.band(normalized)
    const channels = config.channels(normalized)

    radio.patch({
      tuned: {
        key: `${normalized.toFixed(3)}/${channel}`,
        frequency: normalized,
        channel,
        label: band?.label ?? null,
        channelLabel: channels[channel - 1] ?? null,
      },
      receiving: false,
    })
    play('tune')
  },

  /** Moves to the next or previous channel of the tuned frequency, wrapping around. */
  cycleChannel(direction: 1 | -1): boolean {
    const tuned = radio.state.tuned

    if (!tuned) {
      return false
    }

    const count = config.channels(tuned.frequency).length

    if (count < 2) {
      return false
    }

    const next = ((tuned.channel - 1 + direction + count) % count) + 1

    actions.tune(tuned.frequency, next)

    return true
  },

  leave(): void {
    if (inGame) {
      void sendNuiCallback('leave')
      return
    }

    radio.patch({ tuned: null, receiving: false })
  },

  setVolume(value: number): void {
    const volume = radio.clampVolume(value)

    radio.patch({ volume })

    if (inGame) {
      void sendNuiCallback('volume', { value: volume })
    }
  },

  /** Raises an emergency alert to the whole service. The server has the last word. */
  alert(): boolean {
    const tuned = radio.state.tuned

    if (!tuned) {
      ui.notify(m.emergency_untuned(), 'error')
      play('error')
      return false
    }

    if (!config.canAlert(tuned.frequency)) {
      ui.notify(config.alerts.enabled ? m.alert_refused_job() : m.alert_refused_disabled(), 'error')
      play('error')
      return false
    }

    if (inGame) {
      void sendNuiCallback('alert')
      return true
    }

    play('alert')

    return true
  },

  close(): void {
    if (inGame) {
      void sendNuiCallback('close')
      return
    }

    radio.setVisible(false)
  },

  /**
   * Switches the device off: off the air, display away, and the boot
   * sequence again the next time it opens. The game leaves the frequency
   * and hides the interface; the browser does the same on its own.
   */
  powerOff(): void {
    ui.home()
    radio.reboot()

    if (inGame) {
      void sendNuiCallback('power')
      return
    }

    radio.patch({ tuned: null, receiving: false, transmitting: false })
    radio.setVisible(false)
  },
}
