<script setup lang="ts"></script>

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
