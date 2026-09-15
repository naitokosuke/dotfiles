<script setup lang="ts">
/**
 * Generic tab strip. A horizontally scrolling `<header>` that
 * lays its slot children (`<Tab>` primitives, typically) in a
 * row and fills any remaining space with an under-line spacer.
 *
 * The bar knows nothing about which tabs to show or what
 * happens when they're clicked — the caller passes the tabs
 * through the default slot.
 */
</script>

<template>
  <header class="tabs">
    <slot />
    <div class="tabs-spacer" />
  </header>
</template>

<style scoped>
.tabs {
  display: flex;
  align-items: stretch;
  height: 36px;
  background: var(--bg-elev-1);
  border-bottom: 1px solid var(--border-1);
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none;

  &::-webkit-scrollbar {
    display: none;
  }

  .tabs-spacer {
    flex: 1 1 auto;
    border-bottom: 1px solid var(--border-1);
    background: var(--bg-elev-1);
    margin-bottom: -1px;
  }
}
</style>
