type Disposer = () => void;

interface Palette {
  readonly dot: string;
  readonly dotNear: string;
}

function paletteFor(dark: boolean): Palette {
  return dark
    ? { dot: "rgba(255, 255, 255, 0.04)", dotNear: "rgba(255, 255, 255, 0.16)" }
    : { dot: "rgba(0, 0, 0, 0.04)", dotNear: "rgba(0, 0, 0, 0.14)" };
}

export function mountDotGrid(canvas: HTMLCanvasElement): Disposer {
  const ctx = canvas.getContext("2d", { alpha: true });
  if (!ctx) return () => undefined;

  const dpr = Math.min(globalThis.devicePixelRatio || 1, 2);
  const motionMql = matchMedia("(prefers-reduced-motion: reduce)");
  const themeMql = matchMedia("(prefers-color-scheme: dark)");

  const state = {
    width: 0,
    height: 0,
    mx: -1,
    my: -1,
    targetMx: -1,
    targetMy: -1,
    raf: 0,
    reduced: motionMql.matches,
    dark: themeMql.matches,
  };

  const resize = () => {
    const rect = canvas.getBoundingClientRect();
    state.width = rect.width;
    state.height = rect.height;
    canvas.width = Math.round(rect.width * dpr);
    canvas.height = Math.round(rect.height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  };
  resize();

  const ro = new ResizeObserver(resize);
  ro.observe(canvas);

  const onPointer = (event: PointerEvent) => {
    const rect = canvas.getBoundingClientRect();
    state.targetMx = event.clientX - rect.left;
    state.targetMy = event.clientY - rect.top;
  };
  const onPointerLeave = () => {
    state.targetMx = -9999;
    state.targetMy = -9999;
  };
  globalThis.addEventListener("pointermove", onPointer, { passive: true });
  document.addEventListener("pointerleave", onPointerLeave);

  const onMotionChange = () => {
    state.reduced = motionMql.matches;
  };
  const onThemeChange = () => {
    state.dark = themeMql.matches;
  };
  motionMql.addEventListener("change", onMotionChange);
  themeMql.addEventListener("change", onThemeChange);

  const CELL = 30;
  const HOVER_RADIUS = 220;

  const tick = (t: number) => {
    if (state.mx < 0) {
      state.mx = state.targetMx;
      state.my = state.targetMy;
    } else {
      state.mx += (state.targetMx - state.mx) * 0.12;
      state.my += (state.targetMy - state.my) * 0.12;
    }

    ctx.clearRect(0, 0, state.width, state.height);

    const palette = paletteFor(state.dark);
    for (let x = CELL / 2; x < state.width; x += CELL) {
      for (let y = CELL / 2; y < state.height; y += CELL) {
        const dx = x - state.mx;
        const dy = y - state.my;
        const dist = Math.hypot(dx, dy);
        const proximity = Math.max(0, 1 - dist / HOVER_RADIUS);
        const wave = state.reduced ? 0 : Math.sin(t / 1200 - dist / 90) * 0.5 + 0.5;
        const r = 0.85 + proximity * 1.9 + wave * 0.3;
        ctx.fillStyle = proximity > 0.18 ? palette.dotNear : palette.dot;
        ctx.beginPath();
        ctx.arc(x, y, r, 0, Math.PI * 2);
        ctx.fill();
      }
    }

    state.raf = requestAnimationFrame(tick);
  };
  state.raf = requestAnimationFrame(tick);

  return () => {
    cancelAnimationFrame(state.raf);
    ro.disconnect();
    globalThis.removeEventListener("pointermove", onPointer);
    document.removeEventListener("pointerleave", onPointerLeave);
    motionMql.removeEventListener("change", onMotionChange);
    themeMql.removeEventListener("change", onThemeChange);
  };
}
