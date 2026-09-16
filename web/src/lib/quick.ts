import { config } from '@/lib/config.svelte'
import { radio } from '@/lib/radio.svelte'

export interface QuickTarget {
  key: string
  label: string
  frequency: number
  channel: number
  /** Whether the device is on it right now. */
  active: boolean
}

const MAX_TARGETS = 6

/**
 * What the home screen offers in one click: the bands of the player's
 * service first, then the frequencies tuned this session, without
 * repeating the reserved ones. The tuned frequency is included and marked.
 */
export const quickTargets = (): QuickTarget[] => {
  const tuned = radio.state.tuned
  const targets: QuickTarget[] = []
  const known = new Set<number>()

  for (const preset of config.access.presets) {
    if (!preset.allowed || known.has(preset.frequency)) {
      continue
    }

    known.add(preset.frequency)
    targets.push({
      key: preset.frequency.toFixed(3),
      label: preset.label,
      frequency: preset.frequency,
      channel: 1,
      active: tuned?.frequency === preset.frequency,
    })
  }

  for (const frequency of radio.recents) {
    if (known.has(frequency) || !config.canTune(frequency)) {
      continue
    }

    known.add(frequency)
    targets.push({
      key: frequency.toFixed(3),
      label: config.band(frequency)?.label ?? frequency.toFixed(3),
      frequency,
      channel: 1,
      active: tuned?.frequency === frequency,
    })
  }

  return targets.slice(0, MAX_TARGETS)
}

/** The channels of the tuned frequency as one-click targets, the current one marked. */
export const channelTargets = (): QuickTarget[] => {
  const tuned = radio.state.tuned

  if (!tuned) {
    return []
  }

  const channels = config.channels(tuned.frequency)

  if (channels.length < 2) {
    return []
  }

  return channels.map((label, index) => ({
    key: `${tuned.frequency.toFixed(3)}/${index + 1}`,
    label,
    frequency: tuned.frequency,
    channel: index + 1,
    active: tuned.channel === index + 1,
  }))
}
