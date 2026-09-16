import { toast } from 'svelte-sonner'
import { config } from '@/lib/config.svelte'
import { m } from '@/lib/i18n.svelte'
import type { RadioRoom } from '@/lib/radio.svelte'

/**
 * The radio's own toasts, shown at the bottom of the screen whether the
 * device is open or in the pocket. They say what the device did, never
 * what the player should do.
 */
export const toasts = {
  tuned(room: RadioRoom): void {
    const name = room.label ?? `${room.frequency.toFixed(3)} MHz`

    toast.success(
      room.channelLabel
        ? m.toast_tuned_channel({ name, channel: room.channelLabel })
        : m.toast_tuned({ name }),
      {
        description: room.label ? `${room.frequency.toFixed(3)} MHz` : undefined,
        duration: config.device.display.toastDuration,
      },
    )
  },

  left(): void {
    toast.info(m.toast_left(), { duration: config.device.display.toastDuration })
  },

  refused(reason: string | undefined): void {
    const text =
      reason === 'job'
        ? m.toast_refused_job()
        : reason === 'access'
          ? m.toast_refused_access()
          : m.toast_refused_invalid()

    toast.warning(text, { duration: config.device.display.toastDuration })
  },

  alert(from: string, label: string, frequency?: number): void {
    toast.error(m.toast_alert({ from, label }), {
      description: frequency !== undefined ? `${frequency.toFixed(3)} MHz` : undefined,
      duration: config.device.display.alertDuration,
    })
  },

  /** The device rings in the pocket: the player has to open it to stop it. */
  openRadio(): void {
    toast.warning(m.alert_open_radio(), { duration: config.device.display.alertDuration })
  },

  alertSent(label: string): void {
    toast.success(m.alert_sent({ label }), { duration: config.device.display.toastDuration })
  },

  alertRefused(reason: string | undefined): void {
    const text =
      reason === 'cooldown'
        ? m.alert_refused_cooldown()
        : reason === 'disabled'
          ? m.alert_refused_disabled()
          : reason === 'untuned'
            ? m.emergency_untuned()
            : m.alert_refused_job()

    toast.warning(text, { duration: config.device.display.toastDuration })
  },
}
