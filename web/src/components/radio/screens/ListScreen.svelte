<script lang="ts">
  import type { Component } from 'svelte'
  import { Check, ChevronLeft } from '@lucide/svelte'

  export interface ListItem {
    id: string
    label: string
    icon?: Component
    value?: string
    active?: boolean
  }

  let {
    title,
    items,
    cursor,
    onPick,
  }: { title: string; items: ListItem[]; cursor: number; onPick: (index: number) => void } =
    $props()

  const VISIBLE = 3

  /** The window of rows shown, kept around the cursor. */
  const start = $derived(
    Math.max(0, Math.min(cursor - Math.floor(VISIBLE / 2), items.length - VISIBLE)),
  )
  const visible = $derived(items.slice(start, start + VISIBLE))
  const thumbHeight = $derived(Math.max(15, (VISIBLE / Math.max(items.length, 1)) * 100))
  const thumbTop = $derived(
    items.length > VISIBLE ? (start / (items.length - VISIBLE)) * (100 - thumbHeight) : 0,
  )
</script>

<div class="flex h-full w-full flex-col gap-[0.25em] px-[6%] py-[4.5%] font-mono">
  <div
    class="flex items-center gap-[0.35em] text-[0.5em] font-semibold uppercase tracking-[0.2em] opacity-80"
  >
    <ChevronLeft class="h-[1.1em] w-[1.1em]" />
    {title}
  </div>

  <div class="flex min-h-0 flex-1 gap-[0.4em]">
    <div class="flex min-h-0 flex-1 flex-col justify-center gap-[0.12em]">
      {#each visible as item, offset (item.id)}
        {@const index = start + offset}
        <button
          type="button"
          class="pointer-events-auto flex items-center gap-[0.45em] rounded-[0.25em] px-[0.5em] py-[0.12em] text-left text-[0.55em] tracking-[0.1em] transition-colors duration-100 {index ===
          cursor
            ? 'bg-[rgba(108,182,246,0.16)] text-[var(--sk-accent-text)] shadow-[inset_0.15em_0_0_var(--sk-accent)]'
            : 'text-white/55'}"
          onclick={() => onPick(index)}
        >
          {#if item.icon}
            <item.icon class="h-[1.1em] w-[1.1em] shrink-0" />
          {/if}
          <span class="min-w-0 flex-1 truncate uppercase">{item.label}</span>
          {#if item.value}
            <span class="shrink-0 opacity-70">{item.value}</span>
          {/if}
          {#if item.active}
            <Check class="h-[1em] w-[1em] shrink-0 text-[var(--sk-accent)]" />
          {/if}
        </button>
      {/each}
    </div>

    {#if items.length > VISIBLE}
      <div class="relative w-[0.16em] rounded-full bg-white/10" aria-hidden="true">
        <div
          class="absolute left-0 w-full rounded-full bg-[var(--sk-accent)]/70"
          style:top="{thumbTop}%"
          style:height="{thumbHeight}%"
        ></div>
      </div>
    {/if}
  </div>
</div>
