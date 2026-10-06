import * as THREE from 'three';
import type { Puzzle } from '../data';
import { Stage } from './stage';
import { computeLayout, type Layout } from './layout';
import { cachedSlab, clearGeoCache, makePiece, type Piece, type PressInfo } from './pieces';
import { disposeObject, glossy, shade } from './geo';
import { ARROW_BACK, ARROW_FACE, BUTTON_COLORS, GOLD, IVORY, JADE, JADE_DARK, SEL_EMISSIVE, VERMILION } from './theme';
import * as paint from './paint';

export interface ViewState {
  filled: ReadonlySet<number>;
  selected: number | null;
  hintsLeft: number;
  seconds: number;
  remaining: number;
  /** 0 off, 1 tap the highlighted tile, 2 tap the highlighted key. */
  tutorial: 0 | 1 | 2;
  tutorialCell: { r: number; c: number } | null;
  tutorialKanji: string | null;
  result: { seconds: number; hintsUsed: number } | null;
  /** performance.now() when the puzzle was completed, else 0. Drives the ripple. */
  winAt: number;
}

const DIM = 0.34;
const BTN_NAMES = ['undo', 'hint', 'next'] as const;

function arrowShape(hw: number, hl: number, sw: number, sl: number): THREE.Shape {
  const s = new THREE.Shape();
  s.moveTo(0, 0);
  s.lineTo(hw, hl);
  s.lineTo(sw, hl);
  s.lineTo(sw, hl + sl);
  s.lineTo(-sw, hl + sl);
  s.lineTo(-sw, hl);
  s.lineTo(-hw, hl);
  s.closePath();
  return s;
}

export class GameView {
  layout!: Layout;
  private puzzle!: Puzzle;
  private built = new THREE.Group();
  private tiles: Piece[] = [];
  private keys: Piece[] = [];
  private btns: Piece[] = [];
  private hud!: { time: Piece; left: Piece; reset: Piece };
  private over: Piece[] = [];
  private all: Piece[] = [];
  private hits: THREE.Object3D[] = [];
  private kanjiToN = new Map<string, number>();
  private state: ViewState | null = null;
  private arrow = new THREE.Group();
  private ray = new THREE.Raycaster();
  private ndc = new THREE.Vector2();
  private held: Piece | null = null;
  private tx = 0;
  private ty = 0;
  private overlayShown = false;
  private reduceMotion = false;
  private builtAspect = 0;

  constructor(private stage: Stage, private onPress: (p: PressInfo) => void) {
    stage.world.add(this.built);
    stage.world.add(this.arrow);
    this.arrow.visible = false;
    this.reduceMotion = !!window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;
    this.buildArrow();
    const c = stage.canvas;
    c.addEventListener('pointerdown', (e) => this.pointerDown(e));
    window.addEventListener('pointerup', () => this.release());
    c.addEventListener('pointermove', (e) => this.pointerMove(e));
    c.addEventListener('pointerleave', () => { this.tx = this.ty = 0; this.release(); });
  }

  // ---- building -------------------------------------------------------------------------

  build(puzzle: Puzzle): void {
    this.clear();
    this.puzzle = puzzle;
    const L = (this.layout = computeLayout(puzzle.rows, puzzle.cols, puzzle.tray.length, window.innerWidth / Math.max(1, window.innerHeight)));
    this.builtAspect = window.innerWidth / Math.max(1, window.innerHeight);
    this.stage.setExtent(L.top, L.bottom);
    this.kanjiToN.clear();
    puzzle.solution.forEach((k, n) => { if (n > 0) this.kanjiToN.set(k, n); });

    const slab = (w: number, h: number, y: number) => {
      const m = new THREE.Mesh(cachedSlab(w, h, 0.4, 0.1, 0.05), glossy(JADE, 0.22));
      m.position.set(0, y, -0.2);
      this.built.add(m);
    };
    slab(L.boardSlabW, L.boardSlabH, 0);
    slab(L.traySlabW, L.traySlabH, L.trayY);

    // Board: open cells are tiles; block cells are dark jade tiles with no label, like the mockup.
    for (let r = 0; r < puzzle.rows; r++) {
      for (let c = 0; c < puzzle.cols; c++) {
        if (puzzle.open[r][c]) continue;
        const b = makePiece({
          x: L.tileX(c), y: L.tileY(r), w: L.tile, h: L.tile, radius: L.radius, bevel: L.bevel,
          backT: L.backT, faceT: L.faceT, faceColor: JADE_DARK, backColor: JADE, labelPx: 16,
          sinkDepth: 0, info: null, labelFit: 1, faceRough: 0.2,
        });
        b.lab.mesh.visible = false;
        b.shadow.visible = false;
        this.built.add(b.group);
      }
    }

    // Board tiles: open cells.
    for (let r = 0; r < puzzle.rows; r++) {
      for (let c = 0; c < puzzle.cols; c++) {
        const n = puzzle.num[r][c];
        if (!n) continue;
        const p = makePiece({
          x: L.tileX(c), y: L.tileY(r), w: L.tile, h: L.tile, radius: L.radius, bevel: L.bevel,
          backT: L.backT, faceT: L.faceT, faceColor: IVORY, backColor: JADE, labelPx: 128,
          sinkDepth: 0.06, info: { kind: 'tile', n, r, c }, labelFit: 1,
        });
        p.n = n;
        this.add(p, this.tiles);
      }
    }

    // Tray keys.
    const kr = 0.22 * (L.key / 1.12);
    const kb = 0.05 * Math.max(L.key / 1.12, 0.6);
    puzzle.tray.forEach((kanji, i) => {
      const slot = L.keySlots[i];
      const p = makePiece({
        x: slot.x, y: slot.y, w: L.key, h: L.key, radius: kr, bevel: kb, backT: L.keyBackT, faceT: L.keyFaceT,
        faceColor: IVORY, backColor: JADE, labelPx: 256, sinkDepth: 0.16, info: { kind: 'key', kanji }, labelFit: 1,
      });
      p.kanji = kanji;
      this.add(p, this.keys);
    });

    // Action tiles.
    const S = L.btn.size;
    BTN_NAMES.forEach((name, i) => {
      const col = BUTTON_COLORS[i];
      const p = makePiece({
        x: L.btn.xs[i], y: L.btn.y, w: S, h: S, radius: (0.2 * S) / 0.9, bevel: 0.05, backT: 0.12, faceT: 0.16,
        faceColor: col, backColor: shade(col, 0.82).getHex(), labelPx: 256, sinkDepth: 0.1, info: { kind: 'btn', name }, labelFit: 1, faceRough: 0.2,
      });
      (p.back.material as THREE.MeshPhysicalMaterial).envMapIntensity = 0.85;
      (p.face.material as THREE.MeshPhysicalMaterial).envMapIntensity = 0.85;
      this.add(p, this.btns);
    });

    // Top bar: time, tiles left, reset.
    const hud = (x: number, w: number, info: PressInfo | null) => makePiece({
      x, y: L.hud.y, w, h: L.hud.h, radius: 0.16, bevel: 0.05, backT: 0.12, faceT: 0.16, faceColor: IVORY, backColor: JADE,
      labelPx: 512, sinkDepth: 0.06, info, labelFit: 0.92,
    });
    this.hud = {
      time: hud(L.hud.time.x, L.hud.time.w, null),
      left: hud(L.hud.left.x, L.hud.left.w, null),
      reset: hud(L.hud.reset.x, L.hud.reset.w, { kind: 'hud', name: 'reset' }),
    };
    const rctx = this.hud.reset;
    paint.paintReset(rctx.lab.ctx, rctx.lab.w, rctx.lab.h);
    rctx.lab.tex.needsUpdate = true;
    this.add(this.hud.time);
    this.add(this.hud.left);
    this.add(rctx);
    this.overlayShown = false;
    if (this.state) this.sync(this.state);
  }

  private add(p: Piece, into?: Piece[]): void {
    this.built.add(p.group, p.shadow);
    this.all.push(p);
    into?.push(p);
    if (p.info) this.hits.push(p.back, p.face);
  }

  private clear(): void {
    for (const child of [...this.built.children]) {
      this.built.remove(child);
      disposeObject(child);
    }
    clearGeoCache();
    this.tiles = []; this.keys = []; this.btns = []; this.over = []; this.all = []; this.hits = [];
    this.held = null;
  }

  private buildArrow(): void {
    // Vermilion face on an ivory back: the arrow is built like a tile.
    const sh = arrowShape(0.3, 0.38, 0.14, 0.42);
    const geo = (d: number) => new THREE.ExtrudeGeometry(sh, { depth: d, bevelEnabled: true, bevelSize: 0.05, bevelThickness: 0.05, bevelSegments: 5 });
    const back = new THREE.Mesh(geo(0.12), glossy(ARROW_BACK, 0.25));
    const face = new THREE.Mesh(geo(0.16), glossy(ARROW_FACE, 0.28));
    face.position.z = 0.12;
    this.arrow.add(back, face);
  }

  /** Rebuilds when the screen shape changes enough (rotation, window resize) to need a new layout. */
  relayoutIfNeeded(): void {
    if (!this.puzzle) return;
    const aspect = window.innerWidth / Math.max(1, window.innerHeight);
    if (Math.abs(aspect - this.builtAspect) > 0.04) this.build(this.puzzle);
  }

  // ---- state -> visuals -----------------------------------------------------------------

  private isDim(p: Piece): boolean {
    const s = this.state;
    const i = p.info;
    if (!s || !s.tutorial || !i) return false;
    if (i.kind === 'tile') return s.tutorial === 1 ? !(s.tutorialCell && i.r === s.tutorialCell.r && i.c === s.tutorialCell.c) : i.n !== s.selected;
    if (i.kind === 'key') return s.tutorial === 1 || i.kanji !== s.tutorialKanji;
    if (i.kind === 'btn') return true;
    return false;
  }

  private colour(p: Piece, face: number, back: number, dim: boolean): void {
    (p.face.material as THREE.MeshPhysicalMaterial).color.copy(shade(face, dim ? DIM : 1));
    (p.back.material as THREE.MeshPhysicalMaterial).color.copy(shade(back, dim ? DIM : 1));
    (p.lab.mesh.material as THREE.MeshBasicMaterial).color.setScalar(dim ? 0.6 : 1);
  }

  private repaint(p: Piece, sig: string, draw: () => void): void {
    if (p.sig === sig) return;
    p.sig = sig;
    draw();
    p.lab.tex.needsUpdate = true;
  }

  sync(s: ViewState): void {
    this.state = s;
    if (!this.puzzle) return;
    const pz = this.puzzle;
    for (const t of this.tiles) {
      const n = t.n!;
      const done = s.filled.has(n);
      const on = n === s.selected && !done;
      const dim = this.isDim(t);
      t.dim = dim;
      t.target = on ? this.layout.lift : 0;
      this.colour(t, on ? GOLD : IVORY, JADE, dim && !on);
      (t.face.material as THREE.MeshPhysicalMaterial).emissive.setHex(on ? SEL_EMISSIVE : 0);
      const i = t.info as { r: number; c: number };
      t.pulse = s.tutorial === 1 && !!s.tutorialCell && i.r === s.tutorialCell.r && i.c === s.tutorialCell.c;
      this.repaint(t, done ? 'd' : 'e', () => paint.paintTile(t.lab.ctx, t.lab.w, n, done ? pz.solution[n] : null));
    }
    for (const k of this.keys) {
      const used = s.filled.has(this.kanjiToN.get(k.kanji!)!);
      const dim = this.isDim(k);
      k.dim = dim;
      k.target = used ? -0.12 : 0;
      this.colour(k, used ? 0x6d685c : IVORY, JADE, dim);
      k.pulse = s.tutorial === 2 && k.kanji === s.tutorialKanji;
      this.repaint(k, used ? 'u' : 'f', () => paint.paintKey(k.lab.ctx, k.lab.w, k.kanji!, used));
    }
    this.btns.forEach((b, i) => {
      const dim = this.isDim(b);
      b.dim = dim;
      this.colour(b, BUTTON_COLORS[i], shade(BUTTON_COLORS[i], 0.82).getHex(), dim);
      const name = BTN_NAMES[i];
      this.repaint(b, `${name}${s.hintsLeft}`, () => paint.paintActionIcon(b.lab.ctx, b.lab.w, name, s.hintsLeft));
    });
    this.repaint(this.hud.time, `t${paint.formatTime(s.seconds)}`, () => paint.paintStat(this.hud.time.lab.ctx, this.hud.time.lab.w, this.hud.time.lab.h, 'clock', paint.formatTime(s.seconds)));
    this.repaint(this.hud.left, `l${s.remaining}`, () => paint.paintStat(this.hud.left.lab.ctx, this.hud.left.lab.w, this.hud.left.lab.h, 'grid', String(s.remaining)));

    if (s.result && !this.overlayShown) this.showResult(s.result);
    if (!s.result && this.overlayShown) this.hideResult();
  }

  // ---- completion overlay: the tray flips into results and one play bar -----------------

  private showResult(r: { seconds: number; hintsUsed: number }): void {
    this.overlayShown = true;
    const L = this.layout;
    const now = performance.now();
    this.keys.forEach((k, i) => { k.flipOut = now + 35 * i; });
    this.btns.forEach((b, i) => { b.flipOut = now + 60 * i; });
    const base = now + 35 * (this.keys.length - 1) + 260;
    const wide = L.traySlabW - 0.45;
    const mk = (x: number, y: number, w: number, h: number, face: number, back: number, delay: number, info: PressInfo | null, radius: number, draw: (x: CanvasRenderingContext2D, w: number, h: number) => void) => {
      const p = makePiece({
        x, y, w, h, radius, bevel: 0.05, backT: 0.12, faceT: 0.16, faceColor: face, backColor: back, labelPx: 512,
        sinkDepth: 0.06, info, labelFit: 0.92, faceRough: 0.22,
      });
      p.overlay = true;
      p.inT = delay;
      p.group.visible = false;
      p.shadow.visible = false;
      draw(p.lab.ctx, p.lab.w, p.lab.h);
      p.lab.tex.needsUpdate = true;
      this.built.add(p.group, p.shadow);
      this.all.push(p);
      this.over.push(p);
      if (info) this.hits.push(p.back, p.face);
      return p;
    };
    const rr = 0.22 * (L.key / 1.12);
    mk(0, L.rowYs[0], wide, L.key, IVORY, JADE, base, null, rr, (x, w, h) => paint.paintStat(x, w, h, 'clock', paint.formatTime(r.seconds)));
    mk(0, L.rowYs[1], wide, L.key, IVORY, JADE, base + 160, null, rr, (x, w, h) => paint.paintStat(x, w, h, 'hint', String(r.hintsUsed)));
    const play = mk(0, L.btn.y, 4.4, 1.04, VERMILION, shade(VERMILION, 0.82).getHex(), base + 320, { kind: 'over', name: 'next' }, 0.3, (x, w, h) => paint.paintPlay(x, w, h));
    play.pulse = true;
  }

  private hideResult(): void {
    this.overlayShown = false;
    for (const p of this.over) {
      this.built.remove(p.group, p.shadow);
      disposeObject(p.group);
      disposeObject(p.shadow);
      this.all.splice(this.all.indexOf(p), 1);
    }
    this.hits = this.hits.filter((h) => !(h.userData.piece as Piece | undefined)?.overlay);
    this.over = [];
    for (const p of [...this.keys, ...this.btns]) {
      p.flipOut = 0;
      p.group.visible = true;
      p.shadow.visible = true;
      p.group.rotation.x = 0;
    }
  }

  // ---- input ----------------------------------------------------------------------------

  private pick(e: PointerEvent): Piece | null {
    const rc = this.stage.canvas.getBoundingClientRect();
    this.ndc.set(((e.clientX - rc.left) / rc.width) * 2 - 1, -((e.clientY - rc.top) / rc.height) * 2 + 1);
    this.ray.setFromCamera(this.ndc, this.stage.camera);
    for (const h of this.ray.intersectObjects(this.hits, false)) {
      const p = h.object.userData.piece as Piece | undefined;
      if (p && p.group.visible && p.info) return p;
    }
    return null;
  }

  private pointerDown(e: PointerEvent): void {
    const p = this.pick(e);
    if (!p || !p.info) return;
    this.held = p;
    p.sinkT = 1;
    this.onPress(p.info);
  }

  private release(): void {
    if (this.held) this.held.sinkT = 0;
    this.held = null;
  }

  private pointerMove(e: PointerEvent): void {
    const rc = this.stage.canvas.getBoundingClientRect();
    this.ty = ((e.clientX - rc.left) / rc.width - 0.5) * 0.46;
    this.tx = ((e.clientY - rc.top) / rc.height - 0.5) * 0.34;
    this.stage.canvas.style.cursor = this.pick(e) ? 'pointer' : 'default';
  }

  shakeKey(kanji: string): void {
    const k = this.keys.find((p) => p.kanji === kanji);
    if (k) k.shake = performance.now();
  }

  // ---- per-frame ------------------------------------------------------------------------

  tick(ts: number): void {
    const w = this.stage.world;
    const sway = this.reduceMotion ? 0 : Math.sin(ts / 2000) * 0.03;
    w.rotation.x += (this.tx + sway - w.rotation.x) * 0.08;
    w.rotation.y += (this.ty - w.rotation.y) * 0.08;

    const s = this.state;
    const L = this.layout;
    if (!L) return;
    const winAt = s?.winAt ?? 0;

    this.tiles.forEach((p, i) => { p.ripple = i; });
    for (const p of this.all) {
      let target = p.target;
      if (winAt && p.info?.kind === 'tile') {
        const k = (ts - winAt) / 260 - p.ripple * 0.35;
        if (k > 0 && k < Math.PI) target = Math.sin(k) * 0.5 * Math.max(L.s, 0.6);
      }
      if (p.pulse) target += 0.1 + 0.1 * Math.sin(ts / 240);
      p.lift += (target - p.lift) * 0.2;
      p.sink += (p.sinkT - p.sink) * 0.35;

      if (p.inT) {
        const kk = Math.min(1, Math.max(0, (ts - p.inT) / 320));
        if (kk > 0) { p.group.visible = true; p.group.rotation.x = (1 - kk) * (-Math.PI / 2); }
        if (kk >= 1) { p.inT = 0; p.group.rotation.x = 0; }
      }
      if (p.flipOut && ts >= p.flipOut) {
        const q = (ts - p.flipOut) / 220;
        if (q >= 1) { p.group.visible = false; p.flipOut = 0; p.group.rotation.x = 0; }
        else p.group.rotation.x = q * Math.PI / 2;
      }

      const sh = p.shake && ts - p.shake < 300 ? Math.sin((ts - p.shake) / 25) * 0.07 * (1 - (ts - p.shake) / 300) : 0;
      const z = p.lift - p.sink * p.sinkDepth;
      p.group.position.set(p.homeX + sh, p.homeY, z);
      const up = Math.max(z, -0.2);
      p.shadow.visible = p.group.visible;
      p.shadow.scale.set((1 + up * 0.9) * p.shAsp, 1 + up * 0.9, 1);
      (p.shadow.material as THREE.MeshBasicMaterial).opacity = Math.max(0.12, 0.5 - up * 0.45);
      p.shadow.position.set(p.homeX + sh + 0.07 + up * 0.18, p.homeY - 0.09 - up * 0.22, -0.045);
    }
    this.updateArrow(ts);
    this.stage.render();
  }

  private updateArrow(ts: number): void {
    const s = this.state;
    let target: Piece | undefined;
    if (s && s.tutorial === 1 && s.tutorialCell) {
      target = this.tiles.find((t) => { const i = t.info as { r: number; c: number }; return i.r === s.tutorialCell!.r && i.c === s.tutorialCell!.c; });
    } else if (s && s.tutorial === 2) {
      target = this.keys.find((k) => k.kanji === s.tutorialKanji);
    }
    this.arrow.visible = !!target;
    if (!target) return;
    const info = target.info!;
    const nominal = info.kind === 'tile' ? this.layout.tile : this.layout.key;
    const sc = Math.min(1, Math.max(0.55, nominal / 0.9));
    const bob = Math.abs(Math.sin(ts / 420));
    this.arrow.scale.setScalar(sc);
    this.arrow.position.set(target.homeX, target.homeY + nominal / 2 + 0.19 * sc - bob * 0.16 * sc, 0.95);
  }
}
