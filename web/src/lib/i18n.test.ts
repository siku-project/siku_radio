import { describe, expect, it } from 'vitest'
import { applyTranslations, m } from './i18n.svelte'
import { locale } from './locale.svelte'

describe('i18n', () => {
  it('serves the compiled message when the game sent nothing', () => {
    expect(m.menu_title()).toBe('Menu')
  })

  it('prefers the string the game pushed for the running language', () => {
    applyTranslations(locale.current, { menu_title: 'Menu radio' })

    expect(m.menu_title()).toBe('Menu radio')
  })

  it('fills placeholders in a pushed string', () => {
    applyTranslations(locale.current, { menu_title: 'Canal {name}' })

    expect((m.menu_title as (inputs?: Record<string, string>) => string)({ name: 'LSPD' })).toBe(
      'Canal LSPD',
    )
  })

  it('switches the language along with the strings', () => {
    applyTranslations('en', { menu_title: 'Radio menu' })

    expect(locale.current).toBe('en')
    expect(m.menu_title()).toBe('Radio menu')
    expect(m.menu_channels()).toBe('Channels')
  })
})
