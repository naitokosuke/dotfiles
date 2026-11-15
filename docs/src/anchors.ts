import type { CodeAnchor, Lang } from "./types.ts";

/**
 * Resolves a walkthrough's code anchor to a 1-based, inclusive line range.
 *
 * `from` is a literal that must occur on exactly one line of the file, so an
 * edit elsewhere cannot make it point at different code. `to` names the last
 * line: the first line from `from` on whose text, without indentation, starts
 * with it. If that line opens a bracket or an indented string, the range runs
 * on to where it closes, so `to` can name the last attribute of a set rather
 * than its closing `};`. Without `to`, the range is the block `from` starts:
 *
 * - Markdown: a heading runs until the next heading of the same or a higher
 *   level.
 * - Everything else: comment lines are skipped to the first line of code. If
 *   that line opens a bracket or an indented string (`{`, `[`, `(`, `''`), the
 *   range ends at the line that closes it at the same indentation; otherwise it
 *   is that one line.
 *
 * Anything that does not resolve throws, so a stale anchor fails the build
 * instead of showing the wrong lines.
 */
export function resolveAnchor(content: string, lang: Lang, anchor: CodeAnchor): [number, number] {
  const lines = content.split("\n");
  const matches = lines.flatMap((line, i) => (line.includes(anchor.from) ? [i] : []));
  if (matches.length !== 1) {
    throw new Error(
      `anchor ${JSON.stringify(anchor.from)} matches ${matches.length} lines, expected exactly one`,
    );
  }
  const start = matches[0] as number;

  if (anchor.to !== undefined) {
    const to = anchor.to;
    const end = lines.findIndex((line, i) => i >= start && line.trimStart().startsWith(to));
    if (end === -1) {
      throw new Error(
        `anchor end ${JSON.stringify(to)} not found after ${JSON.stringify(anchor.from)}`,
      );
    }
    return [start + 1, (lang === "md" ? end : closingLine(lines, end)) + 1];
  }

  const end = lang === "md" ? markdownSectionEnd(lines, start) : blockEnd(lines, start, lang);
  return [start + 1, end + 1];
}

const headingLevel = (line: string): number => /^(#{1,6})\s/.exec(line)?.[1]?.length ?? 0;

function markdownSectionEnd(lines: readonly string[], start: number): number {
  const level = headingLevel(lines[start] ?? "");
  if (level === 0) return start;
  let end = lines.length - 1;
  let inFence = false;
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i] ?? "";
    if (line.trimStart().startsWith("```")) inFence = !inFence;
    const next = inFence ? 0 : headingLevel(line);
    if (next > 0 && next <= level) {
      end = i - 1;
      break;
    }
  }
  while (end > start && (lines[end] ?? "").trim() === "") end--;
  return end;
}

const commentPrefix: Partial<Record<Lang, string>> = {
  nix: "#",
  yaml: "#",
  toml: "#",
  ts: "//",
};

const indentOf = (line: string): number => line.length - line.trimStart().length;

function blockEnd(lines: readonly string[], start: number, lang: Lang): number {
  const prefix = commentPrefix[lang];
  let head = start;
  while (prefix && (lines[head] ?? "").trimStart().startsWith(prefix) && head < lines.length - 1) {
    head++;
  }
  return closingLine(lines, head);
}

/** The line closing the bracket or indented string that `head` opens, or `head` itself. */
function closingLine(lines: readonly string[], head: number): number {
  const opener = (lines[head] ?? "").trimEnd();
  if (!/(\{|\[|\(|'')$/.test(opener)) return head;
  const indent = indentOf(opener);
  for (let i = head + 1; i < lines.length; i++) {
    const line = lines[i] ?? "";
    if (
      line.trim() !== "" &&
      indentOf(line) === indent &&
      /^(\}|\]|\)|'')/.test(line.trimStart())
    ) {
      return i;
    }
  }
  throw new Error(`block opened by ${JSON.stringify(opener.trim())} is never closed`);
}
