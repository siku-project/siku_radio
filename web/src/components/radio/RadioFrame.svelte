<script lang="ts">
  import type { Snippet } from 'svelte'
  import frameUrl from '@/assets/radio_frame.png'

  let { screen, keys }: { screen: Snippet; keys?: Snippet } = $props()
</script>

<div class="radio-frame relative select-none" draggable="false">
  <img src={frameUrl} alt="" class="block h-full w-auto" draggable="false" />

  <div class="radio-frame__screen absolute overflow-hidden">
    {@render screen()}
  </div>

  {#if keys}
    {@render keys()}
  {/if}
</div>

<style>
  /**
   * The frame is a 1024 x 1536 render whose display sits at a fixed place.
   * The screen box is expressed in percentages of the image, so it follows
   * the device whatever its rendered height.
   */
  .radio-frame {
    height: var(--radio-height, 62vh);
    aspect-ratio: 1024 / 1536;
  }

  /**
   * The box is painted opaque black underneath whatever it shows, so the
   * game never shows through while the boot sequence or the main screen
   * fades in or out.
   */
  .radio-frame__screen {
    left: 31%;
    top: 43.2%;
    width: 41.8%;
    height: 17.8%;
    border-radius: 3.5% / 8%;
    background: rgb(3, 4, 6);
    font-size: calc(var(--radio-height, 62vh) * 0.028);
  }
</style>
