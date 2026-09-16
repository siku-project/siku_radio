import { describe, expect, it } from 'vitest'
import { config } from './config.svelte'
import { channelTargets, quickTargets } from './quick'
import { radio } from './radio.svelte'

describe('quick targets', () => {
  it('lists the bands of the service first, then the recents, without repeats', () => {
    config.setJob('police')
    radio.patch({ tuned: null })
    radio.remember(160)
    radio.remember(155.475)

    const targets = quickTargets()

    expect(targets[0]).toMatchObject({ label: 'LSPD', frequency: 155.475, active: false })
    expect(targets.filter((target) => target.frequency === 155.475)).toHaveLength(1)
    expect(targets.some((target) => target.frequency === 160)).toBe(true)
  })

  it('never offers a band of another service to a citizen', () => {
    config.setJob(null)
    radio.remember(155.34)

    expect(quickTargets().some((target) => target.frequency === 155.34)).toBe(false)
  })

  it('marks the tuned frequency and lists its channels', () => {
    config.setJob('ems')
    radio.patch({
      tuned: {
        key: '155.340/2',
        frequency: 155.34,
        channel: 2,
        label: 'EMS',
        channelLabel: 'Field',
      },
    })

    expect(quickTargets().find((target) => target.frequency === 155.34)?.active).toBe(true)
    expect(channelTargets().map((target) => target.label)).toEqual([
      'Dispatch',
      'Field',
      'Hospital',
    ])
    expect(channelTargets()[1]?.active).toBe(true)

    radio.patch({ tuned: null })
    expect(channelTargets()).toEqual([])
  })
})
