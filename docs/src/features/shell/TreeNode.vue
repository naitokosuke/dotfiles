<script setup lang="ts">
import { Link } from "@void/vue";
import { computed } from "vue";
import { iconForFile, icons } from "../../icons.ts";
import type { TreeNode as TreeNodeType } from "../../types.ts";
import { useDirs } from "./useDirs.ts";
import { sidebar } from "./useSidebar.ts";

const props = defineProps<{
  node: TreeNodeType;
  depth: number;
  activePath: string | null;
}>();

const dirs = useDirs();

const depthPx = computed(() => `${props.depth * 12}px`);
const isOpen = computed(() => props.node.type === "dir" && dirs.isOpen(props.node.path));
const isActive = computed(() => props.node.type === "file" && props.activePath === props.node.path);
const folderIcon = computed(() => (isOpen.value ? icons.folderOpen() : icons.folder()));
const chevronIcon = icons.chevronRight({ size: 12 });

function onToggle(): void {
  if (props.node.type === "dir") dirs.toggle(props.node.path);
}

function onFileClick(): void {
  sidebar.menuOpen = false;
}
</script>

<template>
  <div v-if="node.type === 'dir'" class="tree-item tree-dir" :style="{ '--depth': depthPx }">
    <button class="tree-row" type="button" :aria-expanded="isOpen" @click="onToggle">
      <span class="tree-chevron" :class="{ open: isOpen }" v-html="chevronIcon" />
      <span class="tree-icon" v-html="folderIcon" />
      <span class="tree-label">{{ node.name }}</span>
    </button>
    <div v-if="isOpen" class="tree-children">
      <TreeNode
        v-for="child in node.children"
        :key="child.path + child.type"
        :node="child"
        :depth="depth + 1"
        :active-path="activePath"
      />
    </div>
  </div>
  <div
    v-else
    class="tree-item tree-file"
    :class="{ active: isActive }"
    :style="{ '--depth': depthPx }"
  >
    <Link class="tree-row" :href="`/file/${node.path}`" @click="onFileClick">
      <span class="tree-chevron" />
      <span class="tree-icon" v-html="iconForFile(node.name)" />
      <span class="tree-label">{{ node.name }}</span>
    </Link>
  </div>
</template>

<style scoped>
.tree-item {
  display: flex;
  flex-direction: column;

  .tree-row {
    display: grid;
    grid-template-columns: 16px 16px 1fr;
    gap: 4px;
    align-items: center;
    height: 24px;
    padding-inline-start: calc(8px + var(--depth, 0px));
    padding-inline-end: 8px;
    color: var(--fg);
    font-size: 13px;
    white-space: nowrap;
    cursor: pointer;
    width: 100%;
    text-align: left;
    transition:
      background 140ms var(--easing),
      color 140ms var(--easing);

    &:hover {
      background: var(--hover);
    }

    .tree-chevron {
      display: grid;
      place-items: center;
      color: var(--fg-subtle);
      transition: rotate 200ms var(--easing);

      &.open {
        rotate: 90deg;
      }
    }

    .tree-icon {
      display: grid;
      place-items: center;
      color: var(--fg-muted);
    }

    .tree-label {
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }

  .tree-children {
    display: flex;
    flex-direction: column;
  }

  &.tree-dir > .tree-row > .tree-icon {
    color: var(--fg-strong);
    opacity: 0.85;
  }

  &:has(> .tree-row:focus-visible) {
    outline: none;
  }

  &.active > .tree-row {
    background: var(--active);
    color: var(--fg-strong);
  }
}
</style>
