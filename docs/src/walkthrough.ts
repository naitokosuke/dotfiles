/**
 * Reads a file's walkthrough out of its own comments, so the prose lives next
 * to the code it describes instead of in a table that drifts (#614).
 *
 * * The comment block a file opens with is its intro.
 * * A comment line `## <title>` opens a section. The comment lines under it
 *   are the section's prose, and the code directly after them is its excerpt:
 *   the block that code opens (every deeper-indented line), plus its siblings
 *   up to the next blank line.
 */
import type { Lang, Walkthrough, WalkthroughSection } from "./types.ts";

const hashCommentLangs: ReadonlySet<Lang> = new Set(["nix", "toml", "yaml"]);

interface Line {
  readonly indent: number;
  readonly trimmed: string;
}

function toLine(text: string): Line {
  const trimmed = text.trim();
  return { indent: text.length - text.trimStart().length, trimmed };
}

const isBlank = (line: Line): boolean => line.trimmed === "";
const isComment = (line: Line): boolean => line.trimmed.startsWith("#");
const isHeading = (line: Line): boolean => /^## \S/.test(line.trimmed);
const commentBody = (line: Line): string => line.trimmed.replace(/^# ?/, "");

function nextNonBlank(lines: readonly Line[], from: number): number {
  let i = from;
  while (i < lines.length && isBlank(lines[i] as Line)) i++;
  return i;
}

/** 1-based inclusive line range of the excerpt that starts at `start`. */
function excerptRange(lines: readonly Line[], start: number): readonly [number, number] {
  const base = (lines[start] as Line).indent;
  let end = start;
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i] as Line;
    if (isBlank(line)) {
      const next = nextNonBlank(lines, i);
      if (next >= lines.length || (lines[next] as Line).indent <= base) break;
      continue;
    }
    if (line.indent < base) break;
    if (line.indent === base && isHeading(line)) break;
    end = i;
  }
  return [start + 1, end + 1];
}

export function parseWalkthrough(content: string, lang: Lang): Walkthrough | undefined {
  if (!hashCommentLangs.has(lang)) return undefined;
  const lines = content.split("\n").map(toLine);

  const introLines: string[] = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i] as Line;
    if (line.indent !== 0 || !isComment(line) || isHeading(line)) break;
    introLines.push(commentBody(line));
    i++;
  }
  const intro = introLines.join("\n").trim();

  const sections: WalkthroughSection[] = [];
  for (; i < lines.length; i++) {
    const heading = lines[i] as Line;
    if (!isHeading(heading)) continue;
    const title = heading.trimmed.slice("## ".length).trim();
    const prose: string[] = [];
    let j = i + 1;
    while (j < lines.length && isComment(lines[j] as Line) && !isHeading(lines[j] as Line)) {
      prose.push(commentBody(lines[j] as Line));
      j++;
    }
    // Only code directly under the comment is its excerpt: a blank line
    // leaves the section without one (e.g. a comment on an intentional
    // absence).
    const code = lines[j];
    const hasCode = code !== undefined && !isBlank(code) && !isHeading(code);
    sections.push({
      title,
      prose: prose.join("\n").trim(),
      ...(hasCode ? { lines: excerptRange(lines, j) } : {}),
    });
    i = j - 1;
  }

  if (!intro && sections.length === 0) return undefined;
  return { ...(intro ? { intro } : {}), sections };
}
