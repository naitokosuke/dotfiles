<script setup lang="ts">
import type { FactTable } from "../../types.ts";

defineProps<{
  table: FactTable;
}>();
</script>

<template>
  <section class="fact-table">
    <h2 class="table-title">{{ table.title }}</h2>
    <p class="table-caption">{{ table.caption }}</p>
    <div class="table-scroller">
      <table>
        <thead>
          <tr>
            <th v-for="column in table.columns" :key="column" scope="col">{{ column }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(row, idx) in table.rows" :key="idx">
            <td
              v-for="(cell, col) in row"
              :key="col"
              :class="{ mono: col === 0, blank: cell === '' }"
              :data-label="table.columns[col]"
            >
              {{ cell }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>

<style scoped>
@import "../../breakpoints.css";

.fact-table {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-top: clamp(16px, 1.6cqi, 22px);
  border-top: 1px solid var(--border-1);

  .table-title {
    margin: 0;
    font-size: clamp(18px, 1.9cqi, 22px);
    line-height: 1.3;
    font-weight: 600;
    letter-spacing: -0.01em;
    color: var(--fg-strong);
  }

  .table-caption {
    margin: 0 0 6px;
    font-size: 12.5px;
    color: var(--fg-muted);
  }

  .table-scroller {
    overflow-x: auto;
    border: 1px solid var(--border-1);
    border-radius: 10px;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
    line-height: 1.5;
  }

  th {
    text-align: start;
    padding: 8px 14px;
    font-family: var(--font-mono);
    font-size: 11px;
    font-weight: 500;
    letter-spacing: 0.04em;
    color: var(--fg-muted);
    background: var(--bg-elev-1);
    border-bottom: 1px solid var(--border-1);
  }

  td {
    padding: 6px 14px;
    color: var(--fg);
    vertical-align: top;
    border-bottom: 1px solid var(--border-1);

    &.mono {
      font-family: var(--font-mono);
      font-size: 12.5px;
      color: var(--fg-strong);
      white-space: nowrap;
    }
  }

  tbody tr:last-child td {
    border-bottom: none;
  }

  /* A phone has no room for columns: each row becomes a block, the first
     cell as its heading and the others labelled underneath. */
  @media (--phone) {
    .table-scroller {
      overflow-x: visible;
    }

    thead {
      display: none;
    }

    tr {
      display: block;
      padding: 10px 14px;
      border-bottom: 1px solid var(--border-1);
    }

    tbody tr:last-child {
      border-bottom: none;
    }

    td {
      display: block;
      padding: 0;
      border-bottom: none;

      &.mono {
        white-space: normal;
        overflow-wrap: anywhere;
      }

      &:not(.mono) {
        margin-top: 4px;
        font-size: 12.5px;
        overflow-wrap: anywhere;

        &.blank {
          display: none;
        }

        &::before {
          content: attr(data-label) " · ";
          color: var(--fg-muted);
          font-family: var(--font-mono);
          font-size: 11px;
        }
      }
    }
  }
}
</style>
