import { escapeHtml } from "../../syntax.ts";

export function renderProse(text: string): string {
  const escaped = escapeHtml(text.trim());
  return escaped
    .split(/\n\s*\n/)
    .map((paragraph) => {
      const inline = paragraph
        .replace(/\s+/g, " ")
        .replace(/`([^`]+)`/g, "<code>$1</code>")
        .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
        .replace(
          /\[([^\]]+)\]\(([^)]+)\)/g,
          '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>',
        );
      return `<p>${inline}</p>`;
    })
    .join("");
}
