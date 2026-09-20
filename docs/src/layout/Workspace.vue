<script setup lang="ts">
/**
 * Rendering one tree (rather than swapping between a desktop and a
 * mobile component) keeps the page `<slot />` mounted across the
 * breakpoint — swapping the wrapper used to tear the page content
 * down and never remount it, leaving mobile viewports blank.
 */
import { useRouter } from "@void/vue";
import { computed, onBeforeUnmount, onMounted, watch } from "vue";
import BottomNav from "../features/shell/BottomNav.vue";
import EditorTabs from "../features/shell/EditorTabs.vue";
import SidebarExplorer from "../features/shell/SidebarExplorer.vue";
import TitleBar from "../features/shell/TitleBar.vue";
import { useDirs } from "../features/shell/useDirs.ts";
import {
  DEFAULT_W,
  resetWidth,
  setCollapsed,
  setRawWidth,
  settleWidth,
  sidebar,
  SNAP_W,
  toggleCollapsed,
} from "../features/shell/useSidebar.ts";
import { useTabs } from "../features/shell/useTabs.ts";
import SidebarResizer from "../primitives/SidebarResizer.vue";
import "../style.css";

const router = useRouter();
const dirs = useDirs();
const tabs = useTabs();

const currentPath = computed(() => router.path);

const activeFilePath = computed(() => {
  const path = currentPath.value.replace(/^\/+/, "").replace(/\/+$/, "");
  if (path.startsWith("file/")) return path.slice("file/".length);
  return null;
});
const isHome = computed(() => activeFilePath.value === null);

const workspaceClasses = computed(() => ({
  "sidebar-collapsed": sidebar.collapsed,
  "menu-open": sidebar.menuOpen,
}));

const workspaceStyle = computed(() => ({
  "--sidebar-w": `${sidebar.width}px`,
}));

function closeMenu(): void {
  sidebar.menuOpen = false;
}

watch(
  currentPath,
  (path) => {
    tabs.syncFromPath(path);
    if (activeFilePath.value) dirs.ensureAncestors(activeFilePath.value);
    sidebar.menuOpen = false;
  },
  { immediate: true },
);

function onKey(event: KeyboardEvent): void {
  if (event.key === "Escape" && sidebar.menuOpen) {
    event.preventDefault();
    sidebar.menuOpen = false;
    return;
  }
  if ((event.metaKey || event.ctrlKey) && (event.key === "b" || event.key === "B")) {
    event.preventDefault();
    toggleCollapsed();
    return;
  }
  if ((event.metaKey || event.ctrlKey) && event.key === "w") {
    event.preventDefault();
    tabs.closeTab(tabs.activeKey.value);
  }
}

onMounted(() => {
  document.addEventListener("keydown", onKey);
});

onBeforeUnmount(() => {
  document.removeEventListener("keydown", onKey);
});
</script>

<template>
  <div class="workspace" :class="workspaceClasses" :style="workspaceStyle">
    <TitleBar />
    <main class="editor">
      <EditorTabs />
      <div class="editor-content">
        <slot />
      </div>
    </main>
    <SidebarExplorer :active-path="activeFilePath" />

    <SidebarResizer
      class="desktop-only"
      :width="sidebar.width"
      :collapsed="sidebar.collapsed"
      :snap-at="SNAP_W"
      :default-width="DEFAULT_W"
      @update:width="setRawWidth"
      @update:collapsed="setCollapsed"
      @settle="settleWidth"
      @reset="resetWidth"
    />

    <button
      class="sidebar-backdrop"
      type="button"
      aria-label="Close menu"
      tabindex="-1"
      @click="closeMenu"
    />
    <BottomNav :is-home="isHome" />
  </div>
</template>

<style scoped>
@import "../breakpoints.css";

.workspace {
  display: grid;
  height: 100dvh;
  grid-template-rows: var(--titlebar-h) 1fr;
  grid-template-columns: 1fr var(--sidebar-w);
  grid-template-areas:
    "title   title"
    "editor  sidebar";
  position: relative;

  .editor {
    grid-area: editor;
    background: var(--bg);
    display: grid;
    grid-template-rows: 36px 1fr;
    grid-template-areas:
      "tabs"
      "content";
    min-width: 0;
    min-height: 0;
    overflow: hidden;
    container-type: inline-size;

    .editor-content {
      grid-area: content;
      min-width: 0;
      min-height: 0;
      overflow: hidden;
      position: relative;
    }
  }

  /* Wrapped in `&` to keep the chain anchored to the workspace's own
     data-v attribute (otherwise Vue scoped CSS would emit a
     `.workspace [data-v-xxx] .selector` with an extra descendant
     combinator that never matches). */
  & :deep(.sidebar) {
    grid-area: sidebar;
  }
  & :deep(.sidebar-resizer) {
    position: absolute;
    top: var(--titlebar-h);
    bottom: 0;
    right: calc(var(--sidebar-w) - 3px);
    z-index: 10;
  }

  &.sidebar-collapsed {
    grid-template-columns: 1fr 0px;

    & :deep(.sidebar-resizer) {
      right: 0;
      width: 10px;
    }
    & :deep(.sidebar-resizer::before) {
      inset: 0 4px;
      background: var(--border-2);
    }
    & :deep(.sidebar-resizer:hover::before) {
      background: var(--accent);
    }
  }

  .sidebar-backdrop {
    display: none;
  }

  @media (--tablet) {
    --sidebar-w: 240px;
  }

  @media (--phone) {
    --titlebar-h: 52px;
    --bottomnav-h: 64px;

    grid-template-columns: 1fr;
    grid-template-rows: var(--titlebar-h) 1fr var(--bottomnav-h);
    grid-template-areas:
      "title"
      "editor"
      "bottom";

    /* Multi-document tabs are a desktop metaphor; mobile navigates via
       the bottom nav and the file sheet, and each page carries its own
       breadcrumb. */
    .editor {
      grid-template-rows: 1fr;
      grid-template-areas: "content";
    }
    & :deep(.editor > .tabs) {
      display: none;
    }

    /* The drag-resizer is meaningless once the sidebar is a sheet. */
    & :deep(.sidebar-resizer.desktop-only) {
      display: none;
    }

    .sidebar-backdrop {
      position: fixed;
      inset: 0;
      background: light-dark(rgba(0, 0, 0, 0.32), rgba(0, 0, 0, 0.6));
      backdrop-filter: blur(4px);
      z-index: 18;
      border: 0;
      padding: 0;
      cursor: pointer;
    }

    &.menu-open .sidebar-backdrop {
      display: block;
      animation: backdrop-in 200ms var(--easing);
    }
  }
}

@keyframes backdrop-in {
  from {
    opacity: 0;
  }
}
</style>
