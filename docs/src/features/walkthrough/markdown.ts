import { escapeHtml } from "../../syntax.ts";

function renderInline(text: string): string {
  return text
    .replace(/\s+/g, " ")
    .replace(/`([^`]+)`/g, "<code>$1</code>")
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(
      /\[([^\]]+)\]\(([^)]+)\)/g,
      '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>',
    );
}

/**
 * Paragraphs separated by blank lines, with inline code, bold and links. A
 * paragraph whose lines start with `* ` or `- ` is a list; an indented line
 * continues the item above it, as in a wrapped source comment.
 */
export function renderProse(text: string): string {
  const escaped = escapeHtml(text.trim());
  return escaped
    .split(/\n\s*\n/)
    .map((paragraph) => {
      const lines = paragraph.split("\n");
      if (!/^[*-] /.test(lines[0] ?? "")) return `<p>${renderInline(paragraph)}</p>`;
      const items: string[] = [];
      for (const line of lines) {
        if (/^[*-] /.test(line)) items.push(line.slice(2));
        else items[items.length - 1] += ` ${line}`;
      }
      return `<ul>${items.map((item) => `<li>${renderInline(item)}</li>`).join("")}</ul>`;
    })
    .join("");
}
