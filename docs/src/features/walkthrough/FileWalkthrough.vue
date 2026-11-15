<script setup lang="ts">
import { computed } from "vue";
import { facts, factsFor } from "../../facts.ts";
import CodeBlock from "../../primitives/CodeBlock.vue";
import { highlight } from "../../syntax.ts";
import type { FileEntry } from "../../types.ts";
import FactTable from "./FactTable.vue";
import FileBreadcrumb from "./FileBreadcrumb.vue";
import FullSourceDetails from "./FullSourceDetails.vue";
import { renderProse } from "./markdown.ts";
import WalkthroughSection from "./WalkthroughSection.vue";

const props = defineProps<{
  file: FileEntry;
}>();

const introText = computed(() => props.file.walkthrough?.intro ?? "");
const introHtml = computed(() => (introText.value ? renderProse(introText.value) : ""));
const sections = computed(() => props.file.walkthrough?.sections ?? []);
const hasSections = computed(() => sections.value.length > 0);
const factTables = computed(() => factsFor(props.file.path, facts));

const lineCount = computed(() => props.file.content.split("\n").length);
const charCount = computed(() => props.file.content.length.toLocaleString());
const langLabel = computed(() => props.file.lang.toUpperCase());
const fullHtml = computed(() =>
  hasSections.value ? "" : highlight(props.file.content, props.file.lang),
);
</script>

<template>
  <div class="file-view">
    <FileBreadcrumb :path="file.path" />
    <div class="walkthrough-scroller">
      <article class="walkthrough">
        <div v-if="introHtml" class="walkthrough-intro" v-html="introHtml" />
        <FactTable v-for="table in factTables" :key="table.title" :table="table" />
        <WalkthroughSection
          v-for="(section, idx) in sections"
          :key="idx"
          :section="section"
          :file="file"
        />
        <FullSourceDetails v-if="hasSections" :file="file" />
        <div v-else class="code-scroller">
          <CodeBlock :html="fullHtml" :line-count="lineCount" :lang-class="`lang-${file.lang}`" />
        </div>
      </article>
    </div>
    <footer class="editor-foot">
      <span>{{ lineCount }} lines</span>
      <span>·</span>
      <span>{{ charCount }} chars</span>
      <span>·</span>
      <span>{{ langLabel }}</span>
    </footer>
  </div>
</template>

<style scoped>
@import "../../breakpoints.css";

.file-view {
  display: grid;
  grid-template-rows: 28px 1fr 24px;
  height: 100%;
  min-height: 0;
  min-width: 0;

  .walkthrough-scroller {
    overflow-y: auto;
    overflow-x: hidden;
    overscroll-behavior: contain;
    background: var(--bg);
    min-height: 0;

    .walkthrough {
      max-width: 760px;
      margin: 0 auto;
      padding: clamp(28px, 4cqi, 64px) clamp(20px, 4cqi, 48px) clamp(40px, 5cqi, 80px);
      display: flex;
      flex-direction: column;
      gap: clamp(28px, 3cqi, 40px);

      .walkthrough-intro {
        font-size: clamp(15px, 1.45cqi, 18px);
        line-height: 1.7;
        color: var(--fg);
        text-wrap: pretty;
        max-width: 64ch;
        border-left: 2px solid var(--border-2);
        padding-inline-start: clamp(14px, 1.8cqi, 22px);

        :deep(p) {
          margin: 0 0 0.9em;

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
          padding: 1px 6px;
          border: 1px solid var(--border-1);
          border-radius: 4px;
          background: var(--bg-elev-1);
          color: var(--fg-strong);
          overflow-wrap: anywhere;
        }
      }

      .code-scroller {
        overflow: auto;
        background: var(--bg);
        min-height: 0;
      }
    }
  }

  .editor-foot {
    display: flex;
    align-items: center;
    gap: 8px;
    padding-inline: 16px;
    height: 24px;
    border-top: 1px solid var(--border-1);
    background: var(--bg);
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--fg-muted);

    @media (--phone) {
      padding-inline: 14px;
    }
  }
}
</style>
