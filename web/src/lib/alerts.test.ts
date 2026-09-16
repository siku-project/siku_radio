import { describe, expect, it, vi } from 'vitest'
import { alerts } from './alerts.svelte'

const sample = {
  from: 'Player 2',
  job: 'police',
  label: 'LSPD',
  frequency: 155.475,
  channel: 2,
  channelLabel: 'Patrol',
  at: 1,
}

describe('alerts', () => {
  it('rings until stopped', () => {
    alerts.start(sample)
    expect(alerts.ringing).toBe(true)
    expect(alerts.active?.from).toBe('Player 2')

    alerts.stop()
    expect(alerts.ringing).toBe(false)
    expect(alerts.active).toBeNull()
  })

  it('stops on its own when the server asks for it', () => {
    vi.useFakeTimers()
    alerts.start(sample, 5)
    expect(alerts.ringing).toBe(true)

    vi.advanceTimersByTime(5000)
    expect(alerts.ringing).toBe(false)
    vi.useRealTimers()
  })

  it('replaces a ringing alert with a newer one', () => {
    alerts.start(sample)
    alerts.start({ ...sample, from: 'Player 3' })
    expect(alerts.active?.from).toBe('Player 3')
    alerts.stop()
  })
})
