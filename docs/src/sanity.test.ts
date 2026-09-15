/**
 * Sanity check for the test toolchain itself, not for site behavior.
 * A broken Vitest resolution (e.g. #388) must fail `vp test` loudly
 * instead of hiding behind "No test files found".
 *
 * @module-tag sanity
 */
import { expect, test } from "vite-plus/test";

test("vp test executes a test file", () => {
  expect(true).toBe(true);
});
