<script setup lang="ts">
defineProps<{
  href?: string;
  target?: "_blank";
  ariaLabel?: string;
  ariaPressed?: boolean;
  ariaControls?: string;
  title?: string;
}>();
</script>

<template>
  <a
    v-if="href"
    class="icon-button"
    :href="href"
    :target="target"
    :rel="target === '_blank' ? 'noopener' : undefined"
    :aria-label="ariaLabel"
    :title="title"
  >
    <slot />
  </a>
  <button
    v-else
    class="icon-button"
    type="button"
    :aria-label="ariaLabel"
    :aria-pressed="ariaPressed"
    :aria-controls="ariaControls"
    :title="title"
  >
    <slot />
  </button>
</template>

<style scoped>
.icon-button {
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  border-radius: 6px;
  color: var(--fg-muted);
  text-decoration: none;
  transition:
    color 200ms var(--easing),
    background 200ms var(--easing);

  &:hover {
    background: var(--hover);
    color: var(--fg-strong);
  }

  &[aria-pressed="true"] {
    color: var(--fg-subtle);
    background: var(--hover);
  }
}
</style>
