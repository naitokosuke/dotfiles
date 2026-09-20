<script setup lang="ts">
import { useTemplateRef } from "vue";

const props = withDefaults(
  defineProps<{
    width: number;
    collapsed?: boolean;
    snapAt?: number;
    defaultWidth?: number;
  }>(),
  {
    collapsed: false,
    snapAt: 140,
    defaultWidth: 280,
  },
);

const emit = defineEmits<{
  "update:width": [value: number];
  "update:collapsed": [value: boolean];
  /** Drag has ended; caller should clamp / persist. */
  settle: [value: number];
  /** Double-click — caller should restore defaults. */
  reset: [];
}>();

const resizerRef = useTemplateRef<HTMLDivElement>("resizerRef");

let dragging = false;
let startX = 0;
let startW = 0;
let dragMoved = false;

function onPointerDown(event: PointerEvent): void {
  if (event.button !== 0) return;
  const resizer = resizerRef.value;
  if (!resizer) return;
  dragging = true;
  startX = event.clientX;
  startW = props.collapsed ? 0 : props.width || props.defaultWidth;
  dragMoved = false;
  try {
    resizer.setPointerCapture(event.pointerId);
  } catch {
    /* setPointerCapture can throw on an orphan pointer id. */
  }
  resizer.classList.add("is-active");
  document.body.classList.add("resizing-sidebar");
  event.preventDefault();
}

function onPointerMove(event: PointerEvent): void {
  if (!dragging) return;
  const dx = event.clientX - startX;
  const intended = startW - dx;
  if (Math.abs(dx) > 2) dragMoved = true;
  if (!dragMoved) return;

  if (intended < props.snapAt) {
    if (!props.collapsed) emit("update:collapsed", true);
  } else {
    if (props.collapsed) emit("update:collapsed", false);
    emit("update:width", intended);
  }
}

function endDrag(event: PointerEvent): void {
  if (!dragging) return;
  dragging = false;

  const resizer = resizerRef.value;
  if (resizer) {
    try {
      if (resizer.hasPointerCapture(event.pointerId)) {
        resizer.releasePointerCapture(event.pointerId);
      }
    } catch {
      /* Capture may have already been released. */
    }
    resizer.classList.remove("is-active");
  }
  document.body.classList.remove("resizing-sidebar");

  if (!dragMoved) {
    emit("update:collapsed", !props.collapsed);
    return;
  }
  if (!props.collapsed) emit("settle", props.width);
}

function onDoubleClick(): void {
  emit("reset");
}
</script>

<template>
  <div
    ref="resizerRef"
    class="sidebar-resizer"
    data-resize-sidebar
    role="separator"
    aria-orientation="vertical"
    aria-label="Resize"
    title="Drag to resize · double-click to reset"
    @pointerdown="onPointerDown"
    @pointermove="onPointerMove"
    @pointerup="endDrag"
    @pointercancel="endDrag"
    @lostpointercapture="endDrag"
    @dblclick="onDoubleClick"
  />
</template>

<style scoped>
.sidebar-resizer {
  /* `position: relative` gives `::before` a containing block. */
  position: relative;
  width: 6px;
  cursor: col-resize;
  background: transparent;
  transition: background 160ms var(--easing) 120ms;
  touch-action: none;

  &::before {
    content: "";
    position: absolute;
    inset: 0 2px;
    background: transparent;
    transition: background 160ms var(--easing) 120ms;
  }

  &:hover::before,
  &.is-active::before,
  &:focus-visible::before {
    background: var(--accent);
    transition-delay: 0s;
  }
}
</style>
