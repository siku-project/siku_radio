import { describe, expect, it } from 'vitest'
import { radio } from './radio.svelte'

describe('radio state patches', () => {
  it('reads tuned: false from the game as off the air', () => {
    radio.patch({
      tuned: { key: '160.000/1', frequency: 160, channel: 1, label: null, channelLabel: null },
    })
    expect(radio.state.tuned?.frequency).toBe(160)

    radio.patch({ tuned: false, receiving: false })
    expect(radio.state.tuned).toBeNull()
  })

  it('leaves the frequency alone when a patch does not mention it', () => {
    radio.patch({
      tuned: { key: '160.000/1', frequency: 160, channel: 1, label: null, channelLabel: null },
    })
    radio.patch({ volume: 40 })

    expect(radio.state.tuned?.frequency).toBe(160)
    expect(radio.state.volume).toBe(40)
  })
})
