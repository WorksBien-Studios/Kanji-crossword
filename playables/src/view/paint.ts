import { INK, KANJI_FONT, NUM_COLOR, UI_FONT } from './theme';

export type Ctx = CanvasRenderingContext2D;

// Icon paths on a 24x24 grid, stroked.
export const ICON = {
  undo: { c: [11.5, 13.5], d: 'M9 6 4 11l5 5M4 11h9a6 6 0 0 1 0 10h-3' },
  hint: { c: [12, 12], d: 'M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z' },
  next: { c: [12, 12], d: 'M5 5l7 7-7 7M12 5l7 7-7 7' },
  clock: { c: [12, 12], d: 'M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0zM12 7v5l3 2' },
  grid: { c: [12, 12], d: 'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z' },
  reset: { c: [12, 12], d: 'M20 12a8 8 0 1 1-3-6.2M20 4v5h-5' },
} as const;

function strokeIcon(x: Ctx, d: string, cx: number, cy: number, c: readonly number[], size: number, color: string, lineWidth = 2.4): void {
  const sc = size / 24;
  x.save();
  x.translate(cx - c[0] * sc, cy - c[1] * sc);
  x.scale(sc, sc);
  x.strokeStyle = color;
  x.lineWidth = lineWidth;
  x.lineCap = 'round';
  x.lineJoin = 'round';
  x.stroke(new Path2D(d));
  x.restore();
}

/** Kanji pressed into a face: light lip below-right, ink on top. */
export function carved(x: Ctx, text: string, cx: number, cy: number, size: number, ink = INK): void {
  x.textAlign = 'center';
  x.textBaseline = 'middle';
  x.font = `800 ${Math.round(size)}px ${KANJI_FONT}`;
  const o = size / 56;
  x.fillStyle = 'rgba(255,255,255,.85)';
  x.fillText(text, cx + o, cy + o * 1.3);
  x.fillStyle = 'rgba(120,90,50,.35)';
  x.fillText(text, cx - o * 0.7, cy - o * 0.7);
  x.fillStyle = ink;
  x.fillText(text, cx, cy);
}

/** Board tile: big vermilion number while empty; carved kanji with a black corner number once filled. */
export function paintTile(x: Ctx, size: number, n: number, kanji: string | null): void {
  const f = size / 256;
  x.clearRect(0, 0, size, size);
  const two = n >= 10;
  if (kanji) {
    carved(x, kanji, 140 * f, 146 * f, 150 * f);
    x.fillStyle = INK;
    x.font = `800 ${Math.round((two ? 70 : 88) * f)}px ${UI_FONT}`;
    x.textAlign = 'left';
    x.textBaseline = 'middle';
    x.fillText(String(n), 20 * f, 62 * f);
  } else {
    x.fillStyle = NUM_COLOR;
    x.font = `800 ${Math.round((two ? 120 : 150) * f)}px ${UI_FONT}`;
    x.textAlign = 'center';
    x.textBaseline = 'middle';
    x.fillText(String(n), 128 * f, 140 * f);
  }
}

export function paintKey(x: Ctx, size: number, kanji: string, used: boolean): void {
  x.clearRect(0, 0, size, size);
  x.globalAlpha = used ? 0.45 : 1;
  carved(x, kanji, size / 2, size * 0.54, size * 0.66);
  x.globalAlpha = 1;
}

export function paintActionIcon(x: Ctx, size: number, name: 'undo' | 'hint' | 'next', hintsLeft: number): void {
  x.clearRect(0, 0, size, size);
  const ic = ICON[name];
  strokeIcon(x, ic.d, size / 2, size / 2, ic.c, 0.52 * size * (24 / 18), '#fff', 2.5);
  if (name === 'hint') {
    const r = size * 0.125;
    x.fillStyle = '#fff';
    x.beginPath();
    x.arc(size * 0.83, size * 0.83, r, 0, 6.283);
    x.fill();
    x.fillStyle = '#26303a';
    x.font = `800 ${Math.round(size * 0.18)}px ${UI_FONT}`;
    x.textAlign = 'center';
    x.textBaseline = 'middle';
    x.fillText(String(hintsLeft), size * 0.83, size * 0.84);
  }
}

function fitFont(x: Ctx, text: string, size: number, maxW: number): number {
  let w = 0;
  do {
    x.font = `800 ${Math.round(size)}px ${UI_FONT}`;
    w = x.measureText(text).width;
    size -= 2;
  } while (w > maxW && size > 16);
  return w;
}

/** Icon and text side by side, centred on a wide tile. */
export function paintStat(x: Ctx, w: number, h: number, icon: keyof typeof ICON, text: string, iconColor = INK): void {
  x.clearRect(0, 0, w, h);
  const isz = h * 0.5;
  const gap = h * 0.14;
  const tw = fitFont(x, text, h * 0.56, w * 0.84 - isz - gap);
  const x0 = (w - (isz + gap + tw)) / 2;
  const ic = ICON[icon];
  strokeIcon(x, ic.d, x0 + isz / 2, h / 2, ic.c, isz, iconColor);
  x.textBaseline = 'middle';
  x.textAlign = 'left';
  x.fillStyle = INK;
  x.fillText(text, x0 + isz + gap, h / 2 + h * 0.03);
}

export function paintReset(x: Ctx, w: number, h: number): void {
  x.clearRect(0, 0, w, h);
  const ic = ICON.reset;
  strokeIcon(x, ic.d, w / 2, h / 2, ic.c, h * 0.5, '#1f8a70');
}

export function paintPlay(x: Ctx, w: number, h: number): void {
  x.clearRect(0, 0, w, h);
  const sc = (0.5 * h) / 14;
  x.save();
  x.translate(w / 2 - 11 * sc + 1.5 * sc, h / 2 - 12 * sc);
  x.scale(sc, sc);
  x.fillStyle = '#fff';
  x.strokeStyle = '#fff';
  x.lineJoin = 'round';
  x.lineWidth = 3;
  const p = new Path2D('M8 5l11 7-11 7z');
  x.fill(p);
  x.stroke(p);
  x.restore();
}

export function formatTime(seconds: number): string {
  const s = Math.max(0, Math.floor(seconds));
  const m = Math.floor(s / 60);
  return `${String(m).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`;
}
