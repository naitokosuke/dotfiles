import { defineConfig } from "void/config";

export default defineConfig({
  sourceDir: "src",
  worker: {
    compatibility_date: "2026-02-24",
  },
  head: {
    title: "naitokosuke / dotfiles",
    htmlAttrs: {
      lang: "en",
    },
    meta: [
      {
        charset: "utf-8",
      },
      {
        name: "viewport",
        content: "width=device-width, initial-scale=1.0, viewport-fit=cover",
      },
      {
        name: "color-scheme",
        content: "dark light",
      },
      {
        name: "theme-color",
        content: "#0a0a0a",
      },
      {
        name: "description",
        content:
          "An interactive, VS Code-flavoured walkthrough of @naitokosuke's dotfiles — an Apple Silicon macOS environment declared with Nix, nix-darwin, and home-manager.",
      },
      {
        property: "og:type",
        content: "website",
      },
      {
        property: "og:site_name",
        content: "naitokosuke / dotfiles",
      },
      {
        property: "og:title",
        content: "naitokosuke / dotfiles",
      },
      {
        property: "og:description",
        content:
          "An interactive walkthrough of an Apple Silicon macOS, declared end-to-end in Nix with nix-darwin and home-manager.",
      },
      {
        property: "og:url",
        content: "https://naitokosuke-dotfiles.void.app/",
      },
      {
        property: "og:image",
        content: "https://naitokosuke-dotfiles.void.app/og.png",
      },
      {
        property: "og:image:type",
        content: "image/png",
      },
      {
        property: "og:image:width",
        content: "1200",
      },
      {
        property: "og:image:height",
        content: "630",
      },
      {
        property: "og:image:alt",
        content:
          "naitokosuke / dotfiles — a declarative macOS in Nix, with the Nix snowflake mark.",
      },
      {
        property: "og:locale",
        content: "en_US",
      },
      {
        name: "twitter:card",
        content: "summary_large_image",
      },
      {
        name: "twitter:site",
        content: "@naitokosuke",
      },
      {
        name: "twitter:creator",
        content: "@naitokosuke",
      },
      {
        name: "twitter:title",
        content: "naitokosuke / dotfiles",
      },
      {
        name: "twitter:description",
        content:
          "An interactive walkthrough of an Apple Silicon macOS, declared end-to-end in Nix with nix-darwin and home-manager.",
      },
      {
        name: "twitter:image",
        content: "https://naitokosuke-dotfiles.void.app/og.png",
      },
      {
        name: "twitter:image:alt",
        content:
          "naitokosuke / dotfiles — a declarative macOS in Nix, with the Nix snowflake mark.",
      },
    ],
    link: [
      {
        rel: "icon",
        href: "/favicon.ico",
        sizes: "32x32",
      },
      {
        rel: "icon",
        type: "image/svg+xml",
        href: "/favicon.svg",
      },
      {
        rel: "canonical",
        href: "https://naitokosuke-dotfiles.void.app/",
      },
    ],
  },
});
