interface IconAttrs {
  readonly size?: number;
  readonly className?: string;
}

function svg(path: string, { size = 16, className = "" }: IconAttrs = {}): string {
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" class="${className}">${path}</svg>`;
}

export const icons = {
  chevronRight: (a?: IconAttrs) => svg('<path d="m9 18 6-6-6-6"/>', a),
  folder: (a?: IconAttrs) =>
    svg(
      '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7z"/>',
      a,
    ),
  folderOpen: (a?: IconAttrs) =>
    svg(
      '<path d="M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v1H3V7z"/><path d="M3 9h18l-2 8a2 2 0 0 1-2 1.5H5A2 2 0 0 1 3 17V9z"/>',
      a,
    ),
  file: (a?: IconAttrs) =>
    svg(
      '<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6"/>',
      a,
    ),
  fileMd: (a?: IconAttrs) =>
    svg(
      '<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6"/><path d="M8 14v3M8 14l2 2 2-2v3M16 14v3M14 14h4M14 17h4"/>',
      a,
    ),
  fileNix: (a?: IconAttrs) =>
    svg(
      '<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6"/><circle cx="12" cy="15" r="3"/>',
      a,
    ),
  github: (a?: IconAttrs) =>
    svg(
      '<path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5a4.5 4.5 0 0 0-1.3-3.1c.4-1.1.4-2.3-.1-3.4 0 0-1.1-.3-3.5 1.3a12 12 0 0 0-6.2 0C6.5 2.2 5.5 2.5 5.5 2.5c-.5 1.1-.5 2.3-.1 3.4A4.5 4.5 0 0 0 4 9c0 3.5 3 5.5 6 5.5a4.8 4.8 0 0 0-1 3.5v4"/><path d="M9 18c-4 1.5-5-2-7-2"/>',
      a,
    ),
  twitter: (a?: IconAttrs) =>
    svg(
      '<path d="M23 3a10.9 10.9 0 0 1-3.14 1.53 4.48 4.48 0 0 0-7.86 3v1A10.66 10.66 0 0 1 3 4s-4 9 5 13a11.64 11.64 0 0 1-7 2c9 5 20 0 20-11.5a4.5 4.5 0 0 0-.08-.83A7.72 7.72 0 0 0 23 3z"/>',
      a,
    ),
  explorer: (a?: IconAttrs) =>
    svg(
      '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
      a,
    ),
  info: (a?: IconAttrs) => svg('<circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/>', a),
  branch: (a?: IconAttrs) =>
    svg(
      '<line x1="6" y1="3" x2="6" y2="15"/><circle cx="18" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M18 9a9 9 0 0 1-9 9"/>',
      a,
    ),
  sparkle: (a?: IconAttrs) =>
    svg(
      '<path d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M5.6 18.4l2.1-2.1M16.3 7.7l2.1-2.1"/>',
      a,
    ),
  close: (a?: IconAttrs) => svg('<path d="M18 6 6 18M6 6l12 12"/>', a),
  search: (a?: IconAttrs) => svg('<circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/>', a),
  menu: (a?: IconAttrs) =>
    svg(
      '<line x1="4" y1="7" x2="20" y2="7"/><line x1="4" y1="12" x2="20" y2="12"/><line x1="4" y1="17" x2="14" y2="17"/>',
      a,
    ),
  panelRight: (a?: IconAttrs) =>
    svg(
      '<rect x="3" y="3" width="18" height="18" rx="2"/><line x1="15" y1="3" x2="15" y2="21"/>',
      a,
    ),
};

export function iconForFile(name: string): string {
  if (name.endsWith(".md")) return icons.fileMd();
  if (name.endsWith(".nix")) return icons.fileNix();
  return icons.file();
}
