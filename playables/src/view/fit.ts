/**
 * Exact camera fit.
 *
 * The world layout is fixed (a 5x5 board, a 4x2 tray, three buttons, a top bar), so only the camera
 * changes with the screen. This finds the smallest camera distance at which every corner of the
 * content box stays inside the usable screen area (the viewport minus safe-area insets and a
 * margin), for every pointer-parallax tilt the game can reach, and shifts the content vertically
 * so the spare room is split evenly. Larger is not possible without clipping; smaller would waste
 * screen. fit.test.ts checks both claims against Three.js's own projection.
 */
export interface Insets {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

export interface ContentBox {
  /** Half of the widest object, in world units. */
  halfWidth: number;
  top: number;
  bottom: number;
  /** Lowest and highest points anything reaches, including lifted tiles and the tutorial arrow. */
  zMin: number;
  zMax: number;
}

export interface FitInput {
  width: number;
  height: number;
  insets: Insets;
  /** Clear space kept inside the safe area, in CSS pixels. */
  margin: number;
  fovDeg: number;
  content: ContentBox;
  /** Largest parallax tilt (radians) about x and y, plus idle sway. */
  tilt: { x: number; y: number };
}

export interface FitResult {
  /** Camera distance from the world origin along z. */
  distance: number;
  /** Vertical offset of the world group. */
  worldY: number;
  /** Pixels per world unit on the plane z = 0.35 (the top of a board tile). */
  ppu: number;
  feasible: boolean;
}

/** Rotation applied by Three.js for Euler order XYZ with z = 0: M = Rx(rx) * Ry(ry). */
export function rotate(p: [number, number, number], rx: number, ry: number): [number, number, number] {
  const [x, y, z] = p;
  const x1 = x * Math.cos(ry) + z * Math.sin(ry);
  const z1 = -x * Math.sin(ry) + z * Math.cos(ry);
  const y2 = y * Math.cos(rx) - z1 * Math.sin(rx);
  const z2 = y * Math.sin(rx) + z1 * Math.cos(rx);
  return [x1, y2, z2];
}

export function contentCorners(c: ContentBox): [number, number, number][] {
  const out: [number, number, number][] = [];
  for (const x of [-c.halfWidth, c.halfWidth]) for (const y of [c.bottom, c.top]) for (const z of [c.zMin, c.zMax]) out.push([x, y, z]);
  return out;
}

/** Corners after every extreme tilt (combinations of -t, 0, +t about each axis). */
export function tiltedCorners(c: ContentBox, tilt: { x: number; y: number }): [number, number, number][] {
  const out: [number, number, number][] = [];
  for (const rx of [-tilt.x, 0, tilt.x]) for (const ry of [-tilt.y, 0, tilt.y]) for (const p of contentCorners(c)) out.push(rotate(p, rx, ry));
  return out;
}

/** Usable area in normalised device coordinates. */
export function usableNdc(w: number, h: number, insets: Insets, margin: number) {
  return {
    xLo: (2 * (insets.left + margin)) / w - 1,
    xHi: 1 - (2 * (insets.right + margin)) / w,
    yLo: -1 + (2 * (insets.bottom + margin)) / h,
    yHi: 1 - (2 * (insets.top + margin)) / h,
  };
}

/** For a distance d, the world-Y shift that centres the content, or null when it cannot fit. */
function tryDistance(corners: [number, number, number][], d: number, aspect: number, T: number, u: ReturnType<typeof usableNdc>): number | null {
  let lower = -Infinity;
  let upper = Infinity;
  for (const [x, y, z] of corners) {
    const depth = d - z;
    if (depth <= 0.01) return null;
    const nx = x / (aspect * T * depth);
    if (nx < u.xLo || nx > u.xHi) return null;
    lower = Math.max(lower, u.yLo * T * depth - y);
    upper = Math.min(upper, u.yHi * T * depth - y);
  }
  return lower <= upper ? (lower + upper) / 2 : null;
}

/** Vertical shift that makes distance `d` fit, or null when it would clip. Exposed for the tests. */
export function feasibleAt(input: FitInput, d: number): number | null {
  const T = Math.tan((input.fovDeg * Math.PI) / 360);
  const u = usableNdc(input.width, input.height, input.insets, input.margin);
  return tryDistance(tiltedCorners(input.content, input.tilt), d, input.width / input.height, T, u);
}

export function fitCamera(input: FitInput): FitResult {
  const { width: w, height: h } = input;
  const aspect = w / h;
  const T = Math.tan((input.fovDeg * Math.PI) / 360);
  const u = usableNdc(w, h, input.insets, input.margin);
  const corners = tiltedCorners(input.content, input.tilt);

  let lo = input.content.zMax + 0.05;
  let hi = 400;
  if (tryDistance(corners, hi, aspect, T, u) === null) return { distance: hi, worldY: 0, ppu: h / (2 * T * hi), feasible: false };
  for (let i = 0; i < 80; i++) {
    const mid = (lo + hi) / 2;
    if (tryDistance(corners, mid, aspect, T, u) === null) lo = mid;
    else hi = mid;
  }
  const worldY = tryDistance(corners, hi, aspect, T, u) ?? 0;
  return { distance: hi, worldY, ppu: h / (2 * T * (hi - 0.35)), feasible: true };
}

export function readSafeInsets(): Insets {
  try {
    const el = document.createElement('div');
    el.style.cssText =
      'position:fixed;left:0;top:0;visibility:hidden;pointer-events:none;' +
      'padding:env(safe-area-inset-top,0px) env(safe-area-inset-right,0px) env(safe-area-inset-bottom,0px) env(safe-area-inset-left,0px)';
    document.body.appendChild(el);
    const cs = getComputedStyle(el);
    const px = (v: string) => Number.parseFloat(v) || 0;
    const insets = { top: px(cs.paddingTop), right: px(cs.paddingRight), bottom: px(cs.paddingBottom), left: px(cs.paddingLeft) };
    el.remove();
    return insets;
  } catch {
    return { top: 0, right: 0, bottom: 0, left: 0 };
  }
}

export const FOV = 30;
/** Lowest slab edge and highest thing that ever rises (lifted tiles, ripple, tutorial arrow). */
export const CONTENT_Z_MIN = -0.25;
export const CONTENT_Z_MAX = 1.3;
/** Pointer parallax is up to 0.34/2 rad about x and 0.46/2 about y, plus 0.03 idle sway. */
export const PARALLAX = { x: 0.34, y: 0.46, sway: 0.03 };
export const MAX_TILT = { x: PARALLAX.x / 2 + PARALLAX.sway, y: PARALLAX.y / 2 };

export function safeMargin(w: number, h: number): number {
  return Math.max(8, 0.02 * Math.min(w, h));
}

export function makeFitInput(w: number, h: number, insets: Insets, box: { halfWidth: number; top: number; bottom: number }): FitInput {
  return {
    width: w,
    height: h,
    insets,
    margin: safeMargin(w, h),
    fovDeg: FOV,
    content: { ...box, zMin: CONTENT_Z_MIN, zMax: CONTENT_Z_MAX },
    tilt: MAX_TILT,
  };
}
