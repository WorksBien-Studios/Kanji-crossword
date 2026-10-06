export interface KeySlot {
  x: number;
  y: number;
}

/**
 * World-space layout for one puzzle. The approved mockup was a 5x5 board with 8 keys; real
 * puzzles are up to 10x10 with ~19 kanji, so every size here derives from the puzzle.
 * Units: a mockup tile was 0.9 wide on a 1.1 pitch.
 */
export interface Layout {
  rows: number;
  cols: number;
  pitch: number;
  s: number;
  tile: number;
  bevel: number;
  radius: number;
  backT: number;
  faceT: number;
  lift: number;
  boardSlabW: number;
  boardSlabH: number;
  tileX: (c: number) => number;
  tileY: (r: number) => number;
  hud: { y: number; h: number; time: { x: number; w: number }; left: { x: number; w: number }; reset: { x: number; w: number } };
  trayCols: number;
  trayRows: number;
  keyPitch: number;
  key: number;
  keyBackT: number;
  keyFaceT: number;
  traySlabW: number;
  traySlabH: number;
  trayY: number;
  keySlots: KeySlot[];
  rowYs: number[];
  btn: { y: number; size: number; xs: number[] };
  top: number;
  bottom: number;
}

/** Aim for three tray rows so the board gets the height; a mockup-sized tray (8 keys) uses four columns. */
/** Jade margin around the tiles on a slab. Kept slim so tiles can use the screen width. */
export const SLAB_PAD = 0.3;

export function trayColumns(n: number): number {
  if (n <= 8) return 4;
  return Math.min(8, Math.max(5, Math.ceil(n / 3)));
}

/** World units of width we can rely on. The camera never frames less than 7 units of width, and about 14 units of height. */
export function usableWidth(aspect: number): number {
  return Math.max(7.0, 14.2 * aspect) * 0.955;
}

export function computeLayout(rows: number, cols: number, keyCount: number, aspect = 0.46): Layout {
  const maxW = usableWidth(aspect);
  const bev = 0.05;
  const pitch = Math.min(1.1, (maxW - SLAB_PAD - 2 * bev) / (cols - 1 + 0.9), (6.8 - 0.55) / (rows - 1 + 0.9));
  const s = pitch / 1.1;
  const tile = 0.9 * s;
  const bevel = 0.05 * Math.max(s, 0.55);
  const depthScale = Math.max(s, 0.6);
  const backT = 0.12 * depthScale;
  const faceT = 0.16 * depthScale;
  const boardSlabW = (cols - 1) * pitch + tile + 2 * bevel + SLAB_PAD;
  const boardSlabH = (rows - 1) * pitch + tile + 2 * bevel + SLAB_PAD;
  const slabHalf = boardSlabH / 2 + 0.05;

  const hudH = 0.9;
  const hudY = slabHalf + 0.7 + hudH / 2 + 0.05;
  const hudTop = hudY + hudH / 2 + 0.05;
  // Top bar: three pieces across a fixed 5.4 width, like the mockup's five columns.
  const hud = {
    y: hudY,
    h: hudH,
    time: { x: -1.65, w: 2.0 },
    left: { x: 0.55, w: 2.0 },
    reset: { x: 2.7 - hudH / 2, w: hudH },
  };

  const trayCols = trayColumns(keyCount);
  const trayRows = Math.ceil(keyCount / trayCols);
  const keyPitch = Math.min(1.4, (maxW - SLAB_PAD) / (trayCols - 1 + 0.8));
  const key = keyPitch * 0.8;
  const traySlabW = (trayCols - 1) * keyPitch + key + SLAB_PAD;
  const traySlabH = (trayRows - 1) * keyPitch + key + SLAB_PAD;
  const trayY = -(slabHalf + 0.35) - traySlabH / 2;

  const rowYs: number[] = [];
  for (let r = 0; r < trayRows; r++) rowYs.push(trayY + ((trayRows - 1) / 2 - r) * keyPitch);
  const keySlots: KeySlot[] = [];
  for (let i = 0; i < keyCount; i++) {
    const r = Math.floor(i / trayCols);
    const inRow = Math.min(trayCols, keyCount - r * trayCols);
    keySlots.push({ x: (i - r * trayCols - (inRow - 1) / 2) * keyPitch, y: rowYs[r] });
  }

  const btnSize = 1.04 * 0.92;
  const btnY = trayY - traySlabH / 2 - 0.05 - 0.4 - 1.04 / 2;
  return {
    rows, cols, pitch, s, tile, bevel, radius: 0.16 * s, backT, faceT, lift: 0.22 * depthScale,
    boardSlabW, boardSlabH,
    tileX: (c) => (c - (cols - 1) / 2) * pitch,
    tileY: (r) => ((rows - 1) / 2 - r) * pitch,
    hud, trayCols, trayRows, keyPitch, key, keyBackT: 0.16 * Math.max(key / 1.12, 0.6), keyFaceT: 0.24 * Math.max(key / 1.12, 0.6),
    traySlabW, traySlabH, trayY, keySlots, rowYs,
    btn: { y: btnY, size: btnSize, xs: [-1.9, 0, 1.9] },
    top: hudTop,
    bottom: btnY - 1.04 / 2 - 0.1,
  };
}
