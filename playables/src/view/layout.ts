export type Mode = 'portrait' | 'landscape';

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
  mode: Mode;
  boardX: number;
  trayX: number;
  btnX: number;
  /** Half of the full width of everything drawn. */
  halfWidth: number;
}

/** Jade margin around the tiles on a slab. */
export const SLAB_PAD = 0.45;

/** Four columns for up to 8 kanji (the approved tray); more kanji spread over wider rows. */
export function trayColumns(n: number): number {
  return n <= 8 ? 4 : Math.min(8, Math.max(5, Math.ceil(n / 3)));
}

/**
 * All sizes are in world units and do not depend on the screen: the camera (view/fit.ts) does the
 * scaling. A 5x5 board uses the approved 1.1 pitch; the tray uses the approved 1.4 key pitch.
 */
export function computeLayout(rows: number, cols: number, keyCount: number, mode: Mode = 'portrait'): Layout {
  const pitch = rows <= 5 && cols <= 5 ? 1.1 : Math.min(1.1, 5.3 / cols, 5.9 / rows);
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
  const keyPitch = trayCols <= 4 ? 1.4 : Math.min(1.4, 5.8 / trayCols);
  const key = keyPitch * 0.8;
  const traySlabW = (trayCols - 1) * keyPitch + key + SLAB_PAD;
  const traySlabH = (trayRows - 1) * keyPitch + key + SLAB_PAD;
  const btnSize = 1.04 * 0.92;
  const hudW = 5.4;
  const playW = 4.4;
  const btnXs = [-1.9, 0, 1.9];
  const btnRowW = 2 * 1.9 + btnSize + 0.2;
  const leftBottom = -(slabHalf + 0.05);
  let trayY: number;
  let btnY: number;
  let top: number;
  let bottom: number;
  let boardX = 0;
  let trayX = 0;
  let halfWidth: number;
  if (mode === 'portrait') {
    // One column: top bar, board, tray, buttons.
    trayY = -(slabHalf + 0.35) - traySlabH / 2;
    btnY = trayY - traySlabH / 2 - 0.05 - 0.4 - 1.04 / 2;
    top = hudTop;
    bottom = btnY - 1.04 / 2 - 0.1;
    halfWidth = Math.max(boardSlabW, traySlabW, hudW + 0.1, btnRowW, playW + 0.2) / 2 + 0.1;
  } else {
    // Two columns for wide screens: top bar and board on the left, tray and buttons on the right.
    const leftW = Math.max(boardSlabW, hudW + 0.1);
    const rightW = Math.max(traySlabW, btnRowW, playW + 0.2);
    const gap = 1.0;
    const total = leftW + gap + rightW;
    boardX = -total / 2 + leftW / 2;
    trayX = total / 2 - rightW / 2;
    const yc = (hudTop + leftBottom) / 2;
    const rightH = traySlabH + 0.05 + 0.4 + 1.04;
    const rightTop = yc + rightH / 2;
    trayY = rightTop - traySlabH / 2;
    btnY = trayY - traySlabH / 2 - 0.05 - 0.4 - 1.04 / 2;
    top = Math.max(hudTop, rightTop + 0.05);
    bottom = Math.min(leftBottom, btnY - 1.04 / 2 - 0.1);
    halfWidth = total / 2 + 0.1;
  }

  const rowYs: number[] = [];
  for (let r = 0; r < trayRows; r++) rowYs.push(trayY + ((trayRows - 1) / 2 - r) * keyPitch);
  const keySlots: KeySlot[] = [];
  for (let i = 0; i < keyCount; i++) {
    const r = Math.floor(i / trayCols);
    const inRow = Math.min(trayCols, keyCount - r * trayCols);
    keySlots.push({ x: trayX + (i - r * trayCols - (inRow - 1) / 2) * keyPitch, y: rowYs[r] });
  }
  const hudShift = boardX;
  const hudShifted = {
    y: hud.y,
    h: hud.h,
    time: { x: hud.time.x + hudShift, w: hud.time.w },
    left: { x: hud.left.x + hudShift, w: hud.left.w },
    reset: { x: hud.reset.x + hudShift, w: hud.reset.w },
  };

  return {
    rows, cols, pitch, s, tile, bevel, radius: 0.16 * s, backT, faceT, lift: 0.22 * depthScale,
    boardSlabW, boardSlabH,
    tileX: (c) => boardX + (c - (cols - 1) / 2) * pitch,
    tileY: (r) => ((rows - 1) / 2 - r) * pitch,
    hud: hudShifted, trayCols, trayRows, keyPitch, key, keyBackT: 0.16 * Math.max(key / 1.12, 0.6), keyFaceT: 0.24 * Math.max(key / 1.12, 0.6),
    traySlabW, traySlabH, trayY, keySlots, rowYs,
    btn: { y: btnY, size: btnSize, xs: btnXs.map((x) => trayX + x) },
    top, bottom, mode, boardX, trayX, btnX: trayX, halfWidth,
  };
}

/** Bounding box of everything the layout draws, for the camera fit. Includes bevels and shadows. */
export function contentBox(L: Layout): { halfWidth: number; top: number; bottom: number } {
  return { halfWidth: L.halfWidth, top: L.top + 0.1, bottom: L.bottom - 0.1 };
}
