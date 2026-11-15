import { expect, test } from "vite-plus/test";
import { files } from "./data.ts";

test("every walkthrough section has prose and stays inside its file", () => {
  for (const file of files) {
    const lineCount = file.content.split("\n").length;
    for (const section of file.walkthrough?.sections ?? []) {
      const where = `${file.path}: ${section.title}`;
      expect(section.prose.trim(), where).not.toBe("");
      if (!section.lines) continue;
      const [start, end] = section.lines;
      expect(start, where).toBeGreaterThanOrEqual(1);
      expect(end, where).toBeGreaterThanOrEqual(start);
      expect(end, where).toBeLessThanOrEqual(lineCount);
    }
  }
});
