<script setup lang="ts">
import Sidebar from "../../primitives/Sidebar.vue";
import { icons } from "../../icons.ts";
import SidebarTree from "./SidebarTree.vue";
import { sidebar } from "./useSidebar.ts";

defineProps<{
  activePath: string | null;
}>();

const closeIcon = icons.close({ size: 14 });

function closeMenu(): void {
  sidebar.menuOpen = false;
}
</script>

<template>
  <Sidebar id="sidebar" side="right" :collapsed="sidebar.collapsed" :open="sidebar.menuOpen">
    <template #handle>
      <span aria-hidden="true" />
    </template>
    <template #head>
      <span>Explorer</span>
      <button
        class="sidebar-close"
        type="button"
        aria-label="Close menu"
        @click="closeMenu"
        v-html="closeIcon"
      />
    </template>
    <SidebarTree :active-path="activePath" />
  </Sidebar>
</template>

<style scoped>
@import "../../breakpoints.css";

.sidebar-close {
  display: none;
  place-items: center;
  width: 26px;
  height: 26px;
  border-radius: 6px;
  color: var(--fg-muted);
  transition:
    color 180ms var(--easing),
    background 180ms var(--easing);

  &:hover {
    color: var(--fg-strong);
    background: var(--hover);
  }
}

@media (--phone) {
  .sidebar-close {
    display: inline-grid;
  }
}
</style>
