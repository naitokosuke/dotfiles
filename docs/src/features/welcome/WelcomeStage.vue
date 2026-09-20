<script setup lang="ts">
import { Link } from "@void/vue";
import Card from "../../primitives/Card.vue";
import DotGrid from "../../primitives/DotGrid.vue";
import Logo from "../../primitives/Logo.vue";

interface Entry {
  readonly label: string;
  readonly path: string;
  readonly blurb: string;
}

const entries: ReadonlyArray<Entry> = [
  {
    label: "flake.nix",
    path: "flake.nix",
    blurb: "Entry point — composes inputs and per-host darwinConfigurations.",
  },
  {
    label: "hosts/",
    path: "hosts/common/default.nix",
    blurb: "System declaration layer via nix-darwin.",
  },
  {
    label: "home/",
    path: "home/default.nix",
    blurb: "User declaration layer via home-manager.",
  },
];
</script>

<template>
  <div class="welcome-stage">
    <div class="welcome-bg" aria-hidden="true">
      <DotGrid />
      <Logo class="welcome-logo" variant="nix" />
    </div>
    <div class="welcome-inner">
      <h1><span class="user">naitokosuke</span><span class="slash">/</span>dotfiles</h1>
      <p class="lede">
        An Apple Silicon macOS, declared end-to-end in
        <strong>Nix</strong>. <strong>nix-darwin</strong> owns the system layer and
        <strong>home-manager</strong> owns the user layer — the whole environment rebuilds from
        <code>flake.nix</code> with <code>sudo darwin-rebuild switch --flake .#&lt;host&gt;</code>.
      </p>
      <nav class="entry-row" aria-label="entry points">
        <Link
          v-for="entry in entries"
          :key="entry.path"
          class="entry-link"
          :href="`/file/${entry.path}`"
        >
          <Card interactive>
            <span class="entry-label">{{ entry.label }}</span>
            <span class="entry-blurb">{{ entry.blurb }}</span>
          </Card>
        </Link>
      </nav>
      <p class="attribution">
        Nix logo by Simon Frankau (revised by Tim Cuthbertson) ·
        <a
          href="https://creativecommons.org/licenses/by/4.0/"
          target="_blank"
          rel="noopener noreferrer"
          >CC BY 4.0</a
        >
      </p>
    </div>
  </div>
</template>

<style scoped>
@import "../../breakpoints.css";

.welcome-stage {
  position: relative;
  overflow: hidden;
  isolation: isolate;
  min-width: 0;
  min-height: 0;
  height: 100%;

  .welcome-bg {
    position: absolute;
    inset: 0;
    z-index: 0;
    pointer-events: none;
  }

  .welcome-logo {
    --nix-size: clamp(560px, 92dvw, 1120px);
    position: absolute;
    width: var(--nix-size);
    aspect-ratio: 1;
    right: calc(var(--nix-size) * -0.5);
    bottom: calc(var(--nix-size) * -0.5);
    color: light-dark(rgba(0, 0, 0, 0.085), rgba(255, 255, 255, 0.075));
    filter: blur(0.4px);

    :deep(.rotor) {
      animation: welcome-logo-spin 240s linear infinite;
    }
  }

  .welcome-inner {
    position: relative;
    z-index: 1;
    padding-block: clamp(36px, 6cqi, 80px);
    padding-inline: clamp(20px, 5.5cqi, 56px);
    overflow-y: auto;
    overflow-x: hidden;
    max-width: 1040px;
    margin: 0 auto;
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: safe center;
    gap: clamp(18px, 2.6cqi, 32px);
    box-sizing: border-box;
    overscroll-behavior: contain;

    h1 {
      margin: 0;
      font-size: clamp(22px, 8.2vw, 84px);
      line-height: 1;
      font-weight: 600;
      letter-spacing: -0.045em;
      white-space: nowrap;
      color: var(--fg-strong);

      .slash {
        color: var(--fg-subtle);
        margin-inline: 0.04em;
        font-weight: 200;
      }

      .user {
        font-weight: 300;
        color: var(--fg-muted);
      }
    }

    .lede {
      margin: 0;
      font-size: clamp(15px, 1.4vw, 18px);
      line-height: 1.7;
      color: var(--fg);
      max-width: 62ch;
      text-wrap: pretty;

      strong {
        color: var(--fg-strong);
        font-weight: 600;
      }

      code {
        font-family: var(--font-mono);
        font-size: 0.86em;
        padding: 1px 6px;
        border: 1px solid var(--border-1);
        border-radius: 4px;
        background: light-dark(rgba(255, 255, 255, 0.5), rgba(255, 255, 255, 0.03));
        color: var(--fg-strong);
        overflow-wrap: anywhere;
        word-break: break-word;
      }
    }

    .entry-row {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      grid-auto-rows: 1fr;
      gap: 8px;
      margin-top: 4px;

      .entry-link {
        display: grid;
        height: 100%;
        text-decoration: none;
        color: inherit;
      }

      /* Stretch the card primitive to fill the row so every card in the
         row shares the tallest card's height regardless of blurb length. */
      :deep(.card) {
        height: 100%;
        align-content: start;
      }

      .entry-label {
        font-family: var(--font-mono);
        font-size: 14px;
        font-weight: 600;
        letter-spacing: -0.01em;
        color: var(--fg-strong);
      }

      .entry-blurb {
        font-size: 12.5px;
        line-height: 1.55;
        color: var(--fg-muted);
        text-wrap: pretty;
      }
    }

    .attribution {
      margin: 36px 0 0;
      font-family: var(--font-mono);
      font-size: 10.5px;
      letter-spacing: 0.04em;
      color: var(--fg-subtle);

      a {
        color: var(--fg-muted);
        border-bottom: 1px solid transparent;
        transition:
          color 180ms var(--easing),
          border-color 180ms var(--easing);

        &:hover {
          color: var(--fg-strong);
          border-bottom-color: currentColor;
        }
      }
    }
  }

  @media (--tablet) {
    .welcome-inner .entry-row {
      grid-template-columns: 1fr;
    }
  }

  @media (--phone) {
    .welcome-inner {
      padding: 28px 22px 24px;
      justify-content: flex-start;
      gap: 24px;

      .lede {
        font-size: 14px;
      }
    }
  }
}

@keyframes welcome-logo-spin {
  to {
    rotate: 360deg;
  }
}
</style>
