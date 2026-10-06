import { describe, expect, it } from 'vitest';
import * as THREE from 'three';
import { FOV, MAX_TILT, contentCorners, feasibleAt, fitCamera, makeFitInput, rotate, tiltedCorners, usableNdc, type FitInput, type Insets } from './fit';
import { computeLayout, contentBox, type Mode } from './layout';
import { bestMode, fitsByMode } from './modes';

const NONE: Insets = { top: 0, right: 0, bottom: 0, left: 0 };
const NOTCH: Insets = { top: 47, right: 0, bottom: 34, left: 0 };
const NOTCH_LANDSCAPE: Insets = { top: 0, right: 47, bottom: 21, left: 47 };

const SCREENS: [string, number, number, Insets][] = [
  ['iPhone SE 1', 320, 568, NONE],
  ['Galaxy Fold cover', 280, 653, NONE],
  ['small Android', 360, 640, NONE],
  ['Android 360x780', 360, 780, NONE],
  ['iPhone SE 2', 375, 667, NONE],
  ['iPhone X', 375, 812, NOTCH],
  ['iPhone 14', 390, 844, NOTCH],
  ['iPhone 15 Pro', 393, 852, NOTCH],
  ['Pixel 7', 412, 915, NONE],
  ['iPhone 14 Plus', 428, 926, NOTCH],
  ['iPhone 15 Pro Max', 430, 932, NOTCH],
  ['Galaxy Fold open', 540, 720, NONE],
  ['iPad mini', 768, 1024, NONE],
  ['iPad Pro 11', 834, 1194, NONE],
  ['iPad Pro 12.9', 1024, 1366, NONE],
  ['phone landscape', 844, 390, NOTCH_LANDSCAPE],
  ['phone landscape small', 568, 320, NONE],
  ['iPad landscape', 1024, 768, NONE],
  ['laptop 720p', 1280, 720, NONE],
  ['laptop 768', 1366, 768, NONE],
  ['desktop 1080p', 1920, 1080, NONE],
  ['ultrawide', 2560, 1080, NONE],
  ['super ultrawide', 3440, 1440, NONE],
  ['square', 800, 800, NONE],
  ['tall sliver', 300, 900, NONE],
];

function layoutFor(w: number, h: number, insets: Insets) {
  const mode = bestMode(w, h, insets);
  return { mode, L: computeLayout(5, 5, 8, mode) };
}

function input(w: number, h: number, insets: Insets): FitInput {
  return makeFitInput(w, h, insets, contentBox(layoutFor(w, h, insets).L));
}

describe('layout is identical for every 7- and 8-kanji puzzle', () => {
  for (const mode of ['portrait', 'landscape'] as Mode[]) {
    it(`${mode}: same dimensions for 7 and 8 keys and for any board up to 5x5`, () => {
      const a = computeLayout(5, 5, 8, mode);
      const b = computeLayout(5, 5, 7, mode);
      expect([b.top, b.bottom, b.halfWidth, b.traySlabW, b.traySlabH, b.pitch]).toEqual([a.top, a.bottom, a.halfWidth, a.traySlabW, a.traySlabH, a.pitch]);
      expect(a.pitch).toBe(1.1);
      expect(a.keyPitch).toBe(1.4);
      expect(a.trayCols).toBe(4);
      expect(a.trayRows).toBe(2);
    });
  }

  it('landscape puts the board and the tray side by side without overlap', () => {
    const L = computeLayout(5, 5, 8, 'landscape');
    const boardRight = L.boardX + L.boardSlabW / 2;
    const trayLeft = L.trayX - L.traySlabW / 2;
    expect(trayLeft - boardRight).toBeGreaterThan(0.5);
    expect(L.halfWidth).toBeGreaterThan(Math.max(Math.abs(L.boardX) + L.boardSlabW / 2, Math.abs(L.trayX) + L.traySlabW / 2) - 1e-9);
    for (const x of L.btn.xs) expect(Math.abs(x - L.trayX)).toBeLessThan(L.traySlabW / 2);
  });
});

describe('arrangement choice', () => {
  it('uses one column on tall screens and two on wide ones', () => {
    expect(bestMode(390, 844, NOTCH)).toBe('portrait');
    expect(bestMode(768, 1024, NONE)).toBe('portrait');
    expect(bestMode(844, 390, NOTCH_LANDSCAPE)).toBe('landscape');
    expect(bestMode(1280, 720, NONE)).toBe('landscape');
    expect(bestMode(2560, 1080, NONE)).toBe('landscape');
  });

  it('always picks the arrangement with the larger scale', () => {
    for (const [name, w, h, insets] of SCREENS) {
      const f = fitsByMode(w, h, insets);
      const mode = bestMode(w, h, insets);
      expect(f[mode].ppu, name).toBeGreaterThanOrEqual(Math.max(f.portrait.ppu, f.landscape.ppu) - 1e-9);
    }
  });

  it('does not flip back and forth near the crossover (4% hysteresis)', () => {
    let flips = 0;
    let mode: Mode = bestMode(600, 900, NONE);
    for (let w = 600; w <= 1300; w += 10) {
      const next = bestMode(w, 900, NONE, mode);
      if (next !== mode) flips++;
      mode = next;
    }
    for (let w = 1300; w >= 600; w -= 10) {
      const next = bestMode(w, 900, NONE, mode);
      if (next !== mode) flips++;
      mode = next;
    }
    expect(flips).toBeLessThanOrEqual(2);
  });
});

describe('camera fit', () => {
  for (const [name, w, h, insets] of SCREENS) {
    describe(`${name} ${w}x${h}`, () => {
      const inp = input(w, h, insets);
      const fit = fitCamera(inp);

      it('is feasible', () => expect(fit.feasible).toBe(true));

      it("keeps every corner inside the safe area at every tilt (Three.js's own projection)", () => {
        const cam = new THREE.PerspectiveCamera(FOV, w / h, 0.1, 400);
        cam.position.set(0, 0, fit.distance);
        cam.updateMatrixWorld(true);
        cam.updateProjectionMatrix();
        const u = usableNdc(w, h, insets, inp.margin);
        const world = new THREE.Group();
        world.position.y = fit.worldY;
        for (const rx of [-MAX_TILT.x, 0, MAX_TILT.x]) {
          for (const ry of [-MAX_TILT.y, 0, MAX_TILT.y]) {
            world.rotation.set(rx, ry, 0);
            world.updateMatrixWorld(true);
            for (const c of contentCorners(inp.content)) {
              const p = new THREE.Vector3(...c).applyMatrix4(world.matrixWorld).project(cam);
              expect(p.x).toBeGreaterThanOrEqual(u.xLo - 1e-9);
              expect(p.x).toBeLessThanOrEqual(u.xHi + 1e-9);
              expect(p.y).toBeGreaterThanOrEqual(u.yLo - 1e-9);
              expect(p.y).toBeLessThanOrEqual(u.yHi + 1e-9);
            }
          }
        }
      });

      it('is tight: a camera 0.1% closer would clip something', () => {
        expect(feasibleAt(inp, fit.distance)).not.toBeNull();
        expect(feasibleAt(inp, fit.distance * 0.999)).toBeNull();
      });
    });
  }

  it('my rotation matches Three.js for XYZ Euler angles', () => {
    for (const [rx, ry] of [[0.2, 0.23], [-0.2, 0.1], [0.05, -0.23]]) {
      const e = new THREE.Euler(rx, ry, 0, 'XYZ');
      const m = new THREE.Matrix4().makeRotationFromEuler(e);
      const v = new THREE.Vector3(1.3, -2.1, 0.7).applyMatrix4(m);
      const mine = rotate([1.3, -2.1, 0.7], rx, ry);
      expect(mine[0]).toBeCloseTo(v.x, 12);
      expect(mine[1]).toBeCloseTo(v.y, 12);
      expect(mine[2]).toBeCloseTo(v.z, 12);
    }
  });

  it('uses the largest scale the screen allows: content touches the limiting edge', () => {
    for (const [, w, h, insets] of SCREENS) {
      const inp = input(w, h, insets);
      const fit = fitCamera(inp);
      const u = usableNdc(w, h, insets, inp.margin);
      const T = Math.tan((FOV * Math.PI) / 360);
      let maxX = -Infinity;
      let spanY = 0;
      let lo = Infinity;
      let hi = -Infinity;
      for (const [x, y, z] of tiltedCorners(inp.content, inp.tilt)) {
        const depth = fit.distance - z;
        maxX = Math.max(maxX, Math.abs(x / ((w / h) * T * depth)));
        lo = Math.min(lo, (y + fit.worldY) / (T * depth));
        hi = Math.max(hi, (y + fit.worldY) / (T * depth));
      }
      spanY = hi - lo;
      const touchesX = Math.abs(maxX - u.xHi) < 1e-6 || Math.abs(maxX + u.xLo) < 1e-6;
      const touchesY = Math.abs(spanY - (u.yHi - u.yLo)) < 1e-6;
      expect(touchesX || touchesY).toBe(true);
    }
  });
});

describe('on-screen sizes', () => {
  const rows = SCREENS.map(([name, w, h, insets]) => {
    const { mode, L } = layoutFor(w, h, insets);
    const fit = fitCamera(makeFitInput(w, h, insets, contentBox(L)));
    return { name, w, h, mode, tilePx: L.tile * fit.ppu, keyPx: L.key * fit.ppu, btnPx: L.btn.size * fit.ppu };
  });

  it('prints the table (for the README)', () => {
    // eslint-disable-next-line no-console
    console.table(rows.map((r) => ({ screen: r.name, size: `${r.w}x${r.h}`, layout: r.mode, tile: Math.round(r.tilePx), key: Math.round(r.keyPx), button: Math.round(r.btnPx) })));
    expect(rows.length).toBe(SCREENS.length);
  });

  it('keeps board tiles, keys and buttons at least 32 px on every screen in the matrix (26 px where a side is under 340 px)', () => {
    for (const r of rows) {
      const floor = Math.min(r.w, r.h) < 340 ? 26 : 32;
      expect(r.tilePx, `${r.name} tile`).toBeGreaterThanOrEqual(floor);
      expect(r.keyPx, `${r.name} key`).toBeGreaterThanOrEqual(floor);
      expect(r.btnPx, `${r.name} button`).toBeGreaterThanOrEqual(floor);
    }
  });

  it('keeps keys and buttons at least 44 px (a standard touch target) on phones 375 px or wider', () => {
    for (const r of rows.filter((x) => x.w >= 375 && x.w <= 440 && x.h > x.w)) {
      expect(r.keyPx, `${r.name} key`).toBeGreaterThanOrEqual(44);
      expect(r.btnPx, `${r.name} button`).toBeGreaterThanOrEqual(44);
    }
  });

  it('is never smaller than the one-column layout alone would give', () => {
    for (const [name, w, h, insets] of SCREENS) {
      const f = fitsByMode(w, h, insets);
      const r = rows.find((x) => x.name === name)!;
      const L = computeLayout(5, 5, 8, r.mode);
      expect(L.tile * (r.mode === 'portrait' ? f.portrait.ppu : f.landscape.ppu), name).toBeGreaterThanOrEqual(L.tile * f.portrait.ppu - 1e-9);
    }
  });
});
