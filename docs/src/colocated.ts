import type { Lang, Walkthrough, WalkthroughSection } from "./types.ts";

/**
 * Reads a file's walkthrough from its own comments, so the explanation lives
 * next to the code it explains.
 *
 * - The comment block at the top of the file is the intro.
 * - A comment line `## <title>` opens a section. The comment lines right under
 *   it are the prose, and the code that follows is the excerpt: the line after
 *   the prose, the bracket or indented string it opens through to where that
 *   closes, and any sibling lines after it up to a blank line, a dedent or the
 *   next section. A section inside that block cuts the excerpt short, so a
 *   large attribute set can be explained part by part.
 *
 * Prose is Markdown as `renderProse` understands it; a line with only the
 * comment marker separates paragraphs. Only languages with `#` comments
 * (Nix, YAML, TOML) are read; other files have no walkthrough.
 */
export function readWalkthrough(content: string, lang: Lang): Walkthrough | undefined {
  if (lang !== "nix" && lang !== "yaml" && lang !== "toml") return undefined;
  const lines = content.split("\n");

  const intro: string[] = [];
  for (const line of lines) {
    if (!isComment(line) || sectionTitle(line) !== undefined) break;
    intro.push(commentText(line));
  }

  const sections: WalkthroughSection[] = [];
  for (let i = 0; i < lines.length; i++) {
    const title = sectionTitle(lines[i] ?? "");
    if (title === undefined) continue;
    const prose: string[] = [];
    let next = i + 1;
    while (
      next < lines.length &&
      isComment(lines[next] ?? "") &&
      sectionTitle(lines[next] ?? "") === undefined
    ) {
      prose.push(commentText(lines[next] ?? ""));
      next++;
    }
    const end = excerptEnd(lines, next);
    sections.push({
      title,
      prose: prose.join("\n"),
      ...(end === undefined ? {} : { lines: [next + 1, end + 1] as const }),
    });
    i = next - 1;
  }

  if (intro.length === 0 && sections.length === 0) return undefined;
  return { intro: intro.join("\n"), sections };
}

const isComment = (line: string): boolean => line.trimStart().startsWith("#");

const commentText = (line: string): string => line.trimStart().replace(/^# ?/, "");

function sectionTitle(line: string): string | undefined {
  return /^\s*## +(\S.*)$/.exec(line)?.[1]?.trim();
}

const indentOf = (line: string): number => line.length - line.trimStart().length;

/** The last line of the excerpt starting at `head`, or undefined when no code follows. */
function excerptEnd(lines: readonly string[], head: number): number | undefined {
  const first = lines[head];
  if (first === undefined || first.trim() === "") return undefined;
  const indent = indentOf(first);
  let end = closingLine(lines, head);
  for (let i = end + 1; i < lines.length; i++) {
    const line = lines[i] ?? "";
    if (line.trim() === "" || sectionTitle(line) !== undefined || indentOf(line) < indent) break;
    end = closingLine(lines, i);
    i = end;
  }
  // A section further down, even inside this block, takes over from there.
  const next = lines.findIndex(
    (line, i) => i > head && i <= end && sectionTitle(line) !== undefined,
  );
  if (next !== -1) {
    end = next - 1;
    while (end > head && ((lines[end] ?? "").trim() === "" || isComment(lines[end] ?? ""))) end--;
  }
  return end;
}

/**
 * The last line of what `head` opens, or `head` itself. A line ending in a
 * bracket, `''`, `=` (Nix) or `:` / `|` (YAML) owns the more deeply indented
 * lines after it, and the closing bracket at its own indentation.
 */
function closingLine(lines: readonly string[], head: number): number {
  const opener = (lines[head] ?? "").trimEnd();
  if (!/(\{|\[|\(|''|=|:|\||\|-)$/.test(opener)) return head;
  const indent = indentOf(opener);
  let last = head;
  for (let i = head + 1; i < lines.length; i++) {
    const line = lines[i] ?? "";
    if (line.trim() === "") continue;
    if (indentOf(line) < indent) return last;
    if (indentOf(line) === indent) {
      return /^(\}|\]|\)|'')/.test(line.trimStart()) ? i : last;
    }
    last = i;
  }
  return last;
}
