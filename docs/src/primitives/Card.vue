<script setup lang="ts">
/**
 * The hover lift only applies when the card is `interactive`, so a plain
 * informational card doesn't visually invite a click it can't service.
 */
defineProps<{
  interactive?: boolean;
}>();
</script>

<template>
  <div class="card" :class="{ interactive }">
    <slot />
  </div>
</template>

<style scoped>
.card {
  display: grid;
  gap: 6px;
  padding: 18px 18px 20px;
  border-radius: 12px;
  border: 1px solid var(--border-1);
  background: light-dark(rgba(255, 255, 255, 0.6), rgba(20, 20, 22, 0.4));
  backdrop-filter: blur(8px);
  text-decoration: none;
  color: inherit;
  transition:
    background 200ms var(--easing),
    border-color 200ms var(--easing),
    translate 200ms var(--easing);

  &.interactive:hover {
    background: light-dark(rgba(255, 255, 255, 0.9), rgba(28, 28, 32, 0.6));
    border-color: var(--border-2);
    translate: 0 -2px;
  }
}
</style>
