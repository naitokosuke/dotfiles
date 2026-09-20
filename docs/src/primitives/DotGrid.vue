<script setup lang="ts">
import { onBeforeUnmount, onMounted, useTemplateRef } from "vue";
import { mountDotGrid } from "./dot-grid.ts";

const canvasRef = useTemplateRef<HTMLCanvasElement>("canvasRef");
let dispose: (() => void) | null = null;

onMounted(() => {
  if (canvasRef.value) dispose = mountDotGrid(canvasRef.value);
});

onBeforeUnmount(() => {
  dispose?.();
  dispose = null;
});
</script>

<template>
  <canvas ref="canvasRef" class="dot-grid" aria-hidden="true" />
</template>

<style scoped>
.dot-grid {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}
</style>
