import { expect, test } from "vite-plus/test";
import { files, orphanExplanations } from "./data.ts";

// Importing data.ts resolves every walkthrough anchor, and throws on the first
// one that no longer matches its file.
test("every walkthrough anchor resolves to lines of its file", () => {
  for (const file of files) {
    const lineCount = file.content.split("\n").length;
    for (const section of file.walkthrough?.sections ?? []) {
      if (!section.lines) continue;
      const [start, end] = section.lines;
      expect(start, `${file.path}: ${section.title}`).toBeGreaterThanOrEqual(1);
      expect(end, `${file.path}: ${section.title}`).toBeGreaterThanOrEqual(start);
      expect(end, `${file.path}: ${section.title}`).toBeLessThanOrEqual(lineCount);
    }
  }
});

test("every explanation belongs to a file on the site", () => {
  expect(orphanExplanations).toEqual([]);
});
