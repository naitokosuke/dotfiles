// Adds a background image to VS Code without an extension: appends a rule to
// the workbench CSS inside the app bundle, then updates the CSS checksum in
// product.json so VS Code does not report the install as corrupt.
//
// usage: bun vscode-background.ts [apply|remove]
// VSCODE_APP overrides the app bundle path.

import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";

// Ocean Ripple by Matt Hardy (Unsplash)
const imageUrl =
  "https://images.unsplash.com/photo-1518837695005-2083093ee35b?fm=jpg&q=60&w=3000&auto=format&fit=crop";
const opacity = 0.08;

const app = `${process.env.VSCODE_APP ?? "/Applications/Visual Studio Code.app"}/Contents/Resources/app`;
const cssKey = "vs/workbench/workbench.desktop.main.css";
const cssPath = `${app}/out/${cssKey}`;
const productPath = `${app}/product.json`;

const block = /\n?\/\* vscode-background:begin \*\/[\s\S]*?\/\* vscode-background:end \*\/\n?/g;

const mode = process.argv[2] ?? "apply";
if (mode !== "apply" && mode !== "remove") {
  console.error("usage: vscode-background.ts [apply|remove]");
  process.exit(1);
}

let css = readFileSync(cssPath, "utf8").replace(block, "");
if (mode === "apply") {
  css += `
/* vscode-background:begin */
body::after{content:"";position:fixed;inset:0;z-index:10000;pointer-events:none;background:url("${imageUrl}") center/cover no-repeat;opacity:${opacity}}
/* vscode-background:end */
`;
}
writeFileSync(cssPath, css);

// VS Code stores the SHA-256 as unpadded base64.
const product = JSON.parse(readFileSync(productPath, "utf8"));
product.checksums[cssKey] = createHash("sha256").update(css).digest("base64").replace(/=+$/, "");
// Write in place: product.json keeps its inode, as the bundle is signed.
writeFileSync(productPath, `${JSON.stringify(product, null, "\t")}\n`);

console.log("done: run 'Developer: Reload Window'");
