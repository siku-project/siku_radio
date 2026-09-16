import { describe, expect, it } from 'vitest'
import { config } from './config.svelte'
import { menuEntries } from './menu'
import { radio } from './radio.svelte'

const ids = (): string[] => menuEntries().map((entry) => entry.id)

describe('menu', () => {
  it('hides the alert and the channels from a citizen when a frequency is a channel', () => {
    config.setJob(null)
    config.patch({ frequencies: { ...config.frequencies, open: { mode: 'single', count: 1 } } })

    expect(ids()).not.toContain('emergency')
    expect(ids()).not.toContain('channels')
    expect(config.hasService).toBe(false)
  })

  it('shows the channels to everyone when open frequencies carry them', () => {
    config.setJob(null)
    config.patch({ frequencies: { ...config.frequencies, open: { mode: 'channels', count: 4 } } })

    expect(ids()).toContain('channels')
    expect(ids()).not.toContain('emergency')
  })

  it('shows the alert and the channels to a service member', () => {
    config.setJob('police')
    config.patch({ frequencies: { ...config.frequencies, open: { mode: 'single', count: 1 } } })

    expect(config.hasService).toBe(true)
    expect(ids()).toContain('emergency')
    expect(ids()).toContain('channels')

    config.patch({ alerts: { enabled: false, autoStop: 0 } })
    expect(ids()).not.toContain('emergency')
    config.patch({ alerts: { enabled: true, autoStop: 0 } })
  })

  it('offers to leave the frequency only once one is tuned, and to power off always', () => {
    radio.patch({ tuned: null })
    expect(ids()).not.toContain('leave')
    expect(ids()).toContain('power')

    radio.patch({
      tuned: { key: '160.000/1', frequency: 160, channel: 1, label: null, channelLabel: null },
    })
    expect(ids()).toContain('leave')
  })
})
