<script lang="ts">
  import { onMount } from 'svelte'
  import type { Component } from 'svelte'
  import { alerts } from '@/lib/alerts.svelte'
  import { config, type RadioConfig } from '@/lib/config.svelte'
  import { applyTranslations, m } from '@/lib/i18n.svelte'
  import { locale } from '@/lib/locale.svelte'
  import { RESOURCE, sendNuiCallback } from '@/lib/nui'
  import { radio, type RadioState } from '@/lib/radio.svelte'
  import { play } from '@/lib/sounds'
  import { toasts } from '@/lib/toasts'
  import { ui } from '@/lib/ui.svelte'
  import { Toaster } from '$lib/components/ui/sonner'
  import MainView from '@/views/MainView.svelte'

  interface LocalePayload {
    language?: string
    translations?: { web?: Record<string, string> }
  }

  interface ReadyResponse {
    locale?: LocalePayload
    config?: Partial<RadioConfig>
    state?: Partial<RadioState>
    visible?: boolean
  }

  interface DeviceEvent {
    name?: string
    data?: {
      reason?: string
      from?: string
      job?: string | null
      label?: string
      frequency?: number
      channel?: number
      channelLabel?: string | null
      at?: number
    }
  }

  interface NuiMessage {
    action?: string
    locale?: LocalePayload
    payload?: Partial<RadioState> & Partial<RadioConfig> & DeviceEvent & { visible?: boolean }
  }

  let Shell = $state<Component | null>(null)

  /** The game's language, and the strings it carries when it sends them. */
  const applyLocale = (payload?: LocalePayload): void => {
    if (!payload?.language) {
      return
    }

    const web = payload.translations?.web

    if (web && typeof web === 'object') {
      applyTranslations(payload.language, web)
    } else {
      locale.set(payload.language)
    }
  }

  /** A state patch from the game, with the sounds that go with it. */
  const applyState = (patch: Partial<RadioState>): void => {
    const before = radio.state

    radio.patch(patch)

    if (patch.receiving !== undefined && patch.receiving !== before.receiving) {
      play(patch.receiving ? 'rx_on' : 'rx_off', radio.state.volume / 100)
    }

    if (patch.transmitting !== undefined && patch.transmitting !== before.transmitting) {
      play(patch.transmitting ? 'tx_on' : 'tx_off')
    }

    if (patch.tuned && patch.tuned.key !== before.tuned?.key) {
      play('tune')
    }
  }

  /** Something the game tells the display about: a refusal, an alert. */
  const applyEvent = ({ name, data }: DeviceEvent): void => {
    if (name === 'refused') {
      const reason = data?.reason

      ui.notify(
        reason === 'job'
          ? m.radio_refused_job()
          : reason === 'access'
            ? m.radio_refused_access()
            : m.radio_refused_invalid(),
        'error',
      )
      toasts.refused(reason)
      play('error')
      return
    }

    if (name === 'alert' && data) {
      alerts.start(
        {
          from: data.from ?? '?',
          job: data.job ?? null,
          label: data.label ?? '',
          frequency: data.frequency ?? 0,
          channel: data.channel ?? 1,
          channelLabel: data.channelLabel ?? null,
          at: data.at ?? Math.floor(Date.now() / 1000),
        },
        config.alerts.autoStop,
      )
      toasts.alert(data.from ?? '?', data.label ?? '', data.frequency)

      if (!radio.state.visible) {
        toasts.openRadio()
      }
      return
    }

    if (name === 'alertSent') {
      toasts.alertSent(data?.label ?? '')
      return
    }

    if (name === 'alertRefused') {
      toasts.alertRefused(data?.reason)
    }
  }

  /** A toast whenever the device lands somewhere else, in the game or the browser. */
  let lastKey = $state<string | null | undefined>(undefined)

  $effect(() => {
    const tuned = radio.state.tuned
    const key = tuned?.key ?? null

    if (lastKey === undefined) {
      lastKey = key
      return
    }

    if (key === lastKey) {
      return
    }

    lastKey = key

    if (tuned) {
      toasts.tuned(tuned)
    } else {
      toasts.left()
    }
  })

  const handleMessage = (event: MessageEvent<NuiMessage>): void => {
    const { action, locale: payload, payload: data } = event.data ?? {}

    switch (action) {
      case `${RESOURCE}:nui:setLocale`:
        applyLocale(payload)
        break
      case `${RESOURCE}:nui:setConfig`:
        if (data) {
          config.patch(data)
        }
        break
      case `${RESOURCE}:nui:setVisible`:
        radio.setVisible(data?.visible === true)
        break
      case `${RESOURCE}:nui:setState`:
        if (data) {
          applyState(data)
        }
        break
      case `${RESOURCE}:nui:event`:
        if (data) {
          applyEvent(data)
        }
        break
    }
  }

  onMount(() => {
    window.addEventListener('message', handleMessage)

    void sendNuiCallback<ReadyResponse>('ready').then((answer) => {
      if (!answer) {
        return
      }

      applyLocale(answer.locale)

      if (answer.config) {
        config.patch(answer.config)
        ui.applyDefaults(config.device.sounds, config.device.display.noticeDuration)
      }

      if (answer.state) {
        radio.patch(answer.state)
      }

      if (answer.visible !== undefined) {
        radio.setVisible(answer.visible)
      }
    })

    if (import.meta.env.DEV) {
      void import('@/views/BoilerplateView.svelte').then((module) => {
        Shell = module.default
      })

      const demo = new URLSearchParams(window.location.search).get('toast')

      if (demo === 'alert') {
        alerts.start({
          from: 'Player 2',
          job: 'police',
          label: 'LSPD',
          frequency: 155.475,
          channel: 2,
          channelLabel: 'Patrol',
          at: Math.floor(Date.now() / 1000),
        })
        toasts.alert('Player 2', 'LSPD', 155.475)
      } else if (demo) {
        toasts.tuned({
          key: '155.475/2',
          frequency: 155.475,
          channel: 2,
          label: 'LSPD',
          channelLabel: 'Patrol',
        })
      }
    }

    return () => window.removeEventListener('message', handleMessage)
  })
</script>

{#key locale.current}
  {#if Shell}
    <Shell />
  {:else if !import.meta.env.DEV}
    <MainView />
  {/if}
{/key}

<Toaster />
