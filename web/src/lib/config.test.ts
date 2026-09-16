import { describe, expect, it } from 'vitest'
import { config } from './config.svelte'
import { radio } from './radio.svelte'

describe('config', () => {
  it('snaps a frequency to the grid and refuses one outside the range', () => {
    expect(config.normalize(155.4751)).toBe(155.475)
    expect(config.normalize(155.4774)).toBe(155.475)
    expect(config.normalize(99)).toBeNull()
    expect(config.normalize(Number.NaN)).toBeNull()
  })

  it('reserves a band to its job', () => {
    config.setJob(null)
    expect(config.canTune(155.475)).toBe(false)
    expect(config.canTune(160)).toBe(true)

    config.setJob('police')
    expect(config.canTune(155.475)).toBe(true)
    expect(config.canTune(155.34)).toBe(false)
    expect(config.preset(1)?.allowed).toBe(true)
    expect(config.preset(2)?.allowed).toBe(false)
  })

  it('names the channels of a band and none for an open single frequency', () => {
    expect(config.channels(155.475)).toEqual(['Dispatch', 'Patrol', 'Tactical', 'Detectives'])
    expect(config.channels(160)).toEqual([])
  })
})

describe('keypad entry', () => {
  it('reads six digits as a frequency and pads a short one', () => {
    radio.clearEntry()
    for (const digit of '155475') {
      radio.typeDigit(digit)
    }
    expect(radio.entryFrequency).toBe(155.475)

    radio.clearEntry()
    for (const digit of '1554') {
      radio.typeDigit(digit)
    }
    expect(radio.entryFrequency).toBe(155.4)

    radio.eraseDigit()
    radio.eraseDigit()
    expect(radio.entryFrequency).toBeNull()
  })

  it('keeps the latest frequencies first, without duplicates', () => {
    radio.remember(155.475)
    radio.remember(160)
    radio.remember(155.475)
    expect(radio.recents.slice(0, 2)).toEqual([155.475, 160])
  })
})
