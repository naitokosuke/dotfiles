<script setup lang="ts">
import { computed } from "vue";
import type { FileEntry, WalkthroughSection as Section } from "../../types.ts";
import CodeExcerpt from "./CodeExcerpt.vue";
import { renderProse } from "./markdown.ts";

const props = defineProps<{
  section: Section;
  file: FileEntry;
}>();

const proseHtml = computed(() => renderProse(props.section.prose));
</script>

<template>
  <section class="walkthrough-section">
    <h2 v-if="section.title" class="section-title">{{ section.title }}</h2>
    <div class="section-prose" v-html="proseHtml" />
    <CodeExcerpt v-if="section.lines" :file="file" :range="section.lines" />
  </section>
</template>

<style scoped>
.walkthrough-section {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding-top: clamp(16px, 1.6cqi, 22px);
  border-top: 1px solid var(--border-1);

  .section-title {
    margin: 0;
    font-size: clamp(18px, 1.9cqi, 22px);
    line-height: 1.3;
    font-weight: 600;
    letter-spacing: -0.01em;
    color: var(--fg-strong);
    text-wrap: balance;
  }

  .section-prose {
    font-size: 14.5px;
    line-height: 1.7;
    color: var(--fg);
    text-wrap: pretty;
    max-width: 68ch;

    :deep(p),
    :deep(ul) {
      margin: 0 0 0.85em;

      &:last-child {
        margin-bottom: 0;
      }
    }

    :deep(strong) {
      color: var(--fg-strong);
      font-weight: 600;
    }

    :deep(code) {
      font-family: var(--font-mono);
      font-size: 0.88em;
      padding: 1px 5px;
      border: 1px solid var(--border-1);
      border-radius: 4px;
      background: var(--bg-elev-1);
      color: var(--fg-strong);
      overflow-wrap: anywhere;
    }

    :deep(a) {
      color: var(--fg-strong);
      border-bottom: 1px solid var(--border-2);
      transition: border-color 180ms var(--easing);

      &:hover {
        border-bottom-color: currentColor;
      }
    }
  }
}
</style>
