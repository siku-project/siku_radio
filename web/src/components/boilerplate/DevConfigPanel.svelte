<script lang="ts">
  import { RotateCcw, Settings2 } from '@lucide/svelte'
  import { Button } from '$lib/components/ui/button'
  import * as Dialog from '$lib/components/ui/dialog'
  import { Input } from '$lib/components/ui/input'
  import { Label } from '$lib/components/ui/label'
  import { Separator } from '$lib/components/ui/separator'
  import { Switch } from '$lib/components/ui/switch'
  import * as Tooltip from '$lib/components/ui/tooltip'
  import { alerts } from '@/lib/alerts.svelte'
  import { config } from '@/lib/config.svelte'
  import { radio } from '@/lib/radio.svelte'
  import { play } from '@/lib/sounds'
  import { toasts } from '@/lib/toasts'
  import { ui } from '@/lib/ui.svelte'

  const JOBS: { value: string | null; label: string }[] = [
    { value: null, label: 'None' },
    { value: 'police', label: 'Police' },
    { value: 'ems', label: 'EMS' },
  ]

  let open = $state(false)

  const restricted = $derived(config.access.mode === 'restricted')

  const setRestricted = (value: boolean): void => {
    config.patch({ access: { ...config.access, mode: value ? 'restricted' : 'everyone' } })
  }

  const setAllowed = (value: boolean): void => {
    config.patch({ access: { ...config.access, allowed: value } })
  }

  const setNumber = (key: 'volume' | 'signal' | 'battery', value: string): void => {
    const parsed = Number.parseInt(value, 10)

    if (Number.isFinite(parsed)) {
      radio.patch({ [key]: parsed })
    }
  }

  const setReceiving = (value: boolean): void => {
    radio.patch({ receiving: value })
    play(value ? 'rx_on' : 'rx_off', radio.state.volume / 100)
  }

  const setTransmitting = (value: boolean): void => {
    radio.patch({ transmitting: value })
    play(value ? 'tx_on' : 'tx_off')
  }

  const fakeAlert = (): void => {
    alerts.start({
      from: 'Player 2',
      job: 'police',
      label: radio.state.tuned?.label ?? 'LSPD',
      frequency: radio.state.tuned?.frequency ?? 155.475,
      channel: radio.state.tuned?.channel ?? 1,
      channelLabel: radio.state.tuned?.channelLabel ?? 'Dispatch',
      at: Math.floor(Date.now() / 1000),
    })
    toasts.alert('Player 2', radio.state.tuned?.label ?? 'LSPD', radio.state.tuned?.frequency)
  }
</script>

<div class="fixed bottom-7 left-24 z-50">
  <Tooltip.Provider>
    <Tooltip.Root>
      <Tooltip.Trigger>
        {#snippet child({ props })}
          <Button
            {...props}
            variant="outline"
            size="icon"
            class="sk-panel h-12 w-12 !rounded-full text-sk-soft hover:text-sk"
            onclick={() => (open = true)}
          >
            <Settings2 class="h-[17px] w-[17px]" />
          </Button>
        {/snippet}
      </Tooltip.Trigger>
      <Tooltip.Content side="right" class="sk-panel border-white/[0.08] text-xs text-sk-body">
        Simulation
      </Tooltip.Content>
    </Tooltip.Root>
  </Tooltip.Provider>

  <Dialog.Root bind:open>
    <Dialog.Content
      class="sk-panel sk-scroll max-h-[85vh] w-[460px] gap-0 overflow-y-auto border-white/[0.105] bg-[var(--sk-panel)] p-7 sm:rounded-[var(--sk-radius-panel)]"
    >
      <Dialog.Header class="mb-6 space-y-1 text-center sm:text-center">
        <Dialog.Title class="sk-label text-center font-medium">Simulation</Dialog.Title>
        <Dialog.Description class="text-xs text-sk-faint">
          What the server would send. Nothing here reaches the game.
        </Dialog.Description>
      </Dialog.Header>

      <div class="flex flex-col gap-5">
        <p class="sk-label">Access</p>

        <div class="flex items-center justify-between">
          <Label for="dev-restricted" class="text-sm text-sk-body">Restricted to services</Label>
          <Switch id="dev-restricted" checked={restricted} onCheckedChange={setRestricted} />
        </div>

        <div class="flex items-center justify-between" class:opacity-40={!restricted}>
          <Label for="dev-allowed" class="text-sm text-sk-body">Player holds the permission</Label>
          <Switch
            id="dev-allowed"
            checked={config.access.allowed}
            disabled={!restricted}
            onCheckedChange={setAllowed}
          />
        </div>

        <div class="flex items-center justify-between">
          <span class="text-sm text-sk-body">Job</span>
          <div class="flex gap-1.5">
            {#each JOBS as job (job.label)}
              <button
                type="button"
                class="sk-chip px-3 py-1.5 text-xs {config.access.job === job.value
                  ? 'sk-chip--active'
                  : ''}"
                onclick={() => config.setJob(job.value)}
              >
                {job.label}
              </button>
            {/each}
          </div>
        </div>

        <Separator class="bg-white/[0.085]" />

        <p class="sk-label">Traffic</p>

        <div class="flex items-center justify-between">
          <Label for="dev-tx" class="text-sm text-sk-body">Transmitting</Label>
          <Switch
            id="dev-tx"
            checked={radio.state.transmitting}
            onCheckedChange={setTransmitting}
          />
        </div>

        <div class="flex items-center justify-between">
          <Label for="dev-rx" class="text-sm text-sk-body">Receiving</Label>
          <Switch id="dev-rx" checked={radio.state.receiving} onCheckedChange={setReceiving} />
        </div>

        <div class="flex items-center justify-between">
          <span class="text-sm text-sk-body">Emergency alert received</span>
          <Button
            variant="outline"
            size="sm"
            class="sk-btn sk-btn--ghost h-8 px-3 text-[10px]"
            onclick={fakeAlert}
          >
            Simulate
          </Button>
        </div>

        <Separator class="bg-white/[0.085]" />

        <p class="sk-label">Device</p>

        <div class="grid grid-cols-3 gap-3">
          <div class="flex flex-col gap-1.5">
            <Label for="dev-volume" class="text-xs text-sk-soft">Volume</Label>
            <Input
              id="dev-volume"
              class="sk-field h-9"
              type="number"
              min="0"
              max="100"
              value={radio.state.volume}
              oninput={(event) => setNumber('volume', event.currentTarget.value)}
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <Label for="dev-signal" class="text-xs text-sk-soft">Signal</Label>
            <Input
              id="dev-signal"
              class="sk-field h-9"
              type="number"
              min="0"
              max="4"
              value={radio.state.signal}
              oninput={(event) => setNumber('signal', event.currentTarget.value)}
            />
          </div>
          <div class="flex flex-col gap-1.5">
            <Label for="dev-battery" class="text-xs text-sk-soft">Battery</Label>
            <Input
              id="dev-battery"
              class="sk-field h-9"
              type="number"
              min="0"
              max="100"
              value={radio.state.battery}
              oninput={(event) => setNumber('battery', event.currentTarget.value)}
            />
          </div>
        </div>

        <Separator class="bg-white/[0.085]" />

        <p class="sk-label">Development</p>

        <div class="flex items-center justify-between">
          <Label for="dev-mouse" class="text-sm text-sk-body">Dial up and down with the mouse</Label
          >
          <Switch
            id="dev-mouse"
            checked={ui.mouseNavigation}
            onCheckedChange={(value) => ui.setMouseNavigation(value)}
          />
        </div>

        <Button
          variant="outline"
          class="sk-btn sk-btn--ghost h-11 w-full"
          onclick={() => {
            radio.reboot()
            play('boot')
          }}
        >
          <RotateCcw class="h-3.5 w-3.5" />
          Replay the boot
        </Button>
      </div>
    </Dialog.Content>
  </Dialog.Root>
</div>
