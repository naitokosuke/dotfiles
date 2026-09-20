<script setup lang="ts">
/**
 * `"nix"` path data is verbatim from
 * https://github.com/NixOS/nixos-artwork/blob/master/logo/
 * nix-snowflake-colours.svg (CC BY 4.0, attribution preserved
 * wherever the logo is rendered).
 */
type Variant = "nix";

defineProps<{
  variant: Variant;
}>();
</script>

<template>
  <svg
    v-if="variant === 'nix'"
    class="logo logo-nix"
    viewBox="0 0 501.56251 501.56249"
    xmlns="http://www.w3.org/2000/svg"
    aria-hidden="true"
    focusable="false"
  >
    <g transform="translate(-156.41121, 933.30685)">
      <g class="rotor" transform="matrix(0.99994059,0,0,0.99994059,-0.06321798,33.188377)">
        <path
          id="nix-blade"
          d="m 309.54892,-710.38827 122.19683,211.67512 -56.15706,0.5268 -32.6236,-56.8692 -32.85645,56.5653 -27.90237,-0.011 -14.29086,-24.6896 46.81047,-80.4901 -33.22946,-57.8257 z"
        />
        <use href="#nix-blade" transform="rotate(60, 407.11155, -715.78724)" />
        <use href="#nix-blade" transform="rotate(120, 407.33916, -716.08356)" />
        <use href="#nix-blade" transform="rotate(180, 407.41868, -715.7565)" />
        <use href="#nix-blade" transform="rotate(-120, 407.28823, -715.86995)" />
        <use href="#nix-blade" transform="rotate(-60, 407.31177, -715.70016)" />
      </g>
    </g>
  </svg>
</template>

<style scoped>
.logo {
  display: block;
  fill: currentColor;

  :is(path, use) {
    fill: currentColor;
  }

  .rotor {
    /* Rotate about the snowflake's own geometric center, not the
       viewBox center — the mark is drawn off-center within the
       viewBox, so the default `view-box` reference would make it
       orbit instead of spin in place. */
    transform-box: fill-box;
    transform-origin: center;
  }
}
</style>
