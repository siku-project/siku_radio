<script lang="ts">
  import type { Snippet } from 'svelte'
  import { ChevronLeft } from '@lucide/svelte'

  let { title, children }: { title: string; children: Snippet } = $props()
</script>

<div class="flex h-full w-full flex-col px-[6%] py-[4.5%] font-mono">
  <div
    class="flex items-center gap-[0.35em] text-[0.5em] font-semibold uppercase tracking-[0.2em] opacity-80"
  >
    <ChevronLeft class="h-[1.1em] w-[1.1em]" />
    {title}
  </div>

  <div class="flex min-h-0 flex-1 flex-col items-center justify-center gap-[0.3em] text-center">
    {@render children()}
  </div>
</div>
