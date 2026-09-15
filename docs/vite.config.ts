import { voidVue } from "@void/vue/plugin";
import { defineConfig } from "vite-plus";
import { voidPlugin } from "void";

export default defineConfig({
  css: {
    transformer: "lightningcss",
    lightningcss: {
      drafts: { customMedia: true },
    },
  },
  fmt: {},
  lint: {
    jsPlugins: [{ name: "vite-plus", specifier: "vite-plus/oxlint-plugin" }],
    rules: { "vite-plus/prefer-vite-plus-imports": "error" },
    options: { typeAware: true, typeCheck: true },
  },
  plugins: [voidPlugin(), voidVue()],
  server: {
    fs: {
      allow: [".."],
    },
  },
  test: {
    tags: [
      {
        name: "sanity",
        description: "Proves `vp test` can resolve its Vitest runner and execute a test file.",
      },
    ],
  },
});
