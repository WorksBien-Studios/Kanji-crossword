import * as THREE from 'three';
import { glossy, slab } from './geo';
import type { Ctx } from './paint';

export type PressInfo =
  | { kind: 'tile'; n: number; r: number; c: number }
  | { kind: 'key'; kanji: string }
  | { kind: 'btn'; name: 'undo' | 'hint' | 'next' }
  | { kind: 'hud'; name: 'reset' }
  | { kind: 'over'; name: 'next' };

export interface Label {
  ctx: Ctx;
  tex: THREE.CanvasTexture;
  mesh: THREE.Mesh;
  w: number;
  h: number;
}

/** A tile-like object: jade back, coloured face, a painted label on top and a soft shadow. */
export interface Piece {
  info: PressInfo | null;
  group: THREE.Group;
  back: THREE.Mesh;
  face: THREE.Mesh;
  lab: Label;
  shadow: THREE.Mesh;
  shAsp: number;
  homeX: number;
  homeY: number;
  lift: number;
  target: number;
  sink: number;
  sinkT: number;
  sinkDepth: number;
  sig: string;
  inT: number;
  flipOut: number;
  pulse: boolean;
  shake: number;
  dim: boolean;
  /** Piece is part of the completion overlay (flips in). */
  overlay: boolean;
  ripple: number;
  n?: number;
  kanji?: string;
}

const geoCache = new Map<string, THREE.ExtrudeGeometry>();
export function cachedSlab(w: number, h: number, r: number, d: number, b: number): THREE.ExtrudeGeometry {
  const key = [w, h, r, d, b].map((v) => v.toFixed(4)).join('|');
  let g = geoCache.get(key);
  if (!g) {
    g = slab(w, h, r, d, b);
    geoCache.set(key, g);
  }
  return g;
}
export function clearGeoCache(): void {
  for (const g of geoCache.values()) g.dispose();
  geoCache.clear();
}

let shadowTex: THREE.CanvasTexture | null = null;
function softSquare(): THREE.CanvasTexture {
  if (shadowTex) return shadowTex;
  const c = document.createElement('canvas');
  c.width = c.height = 128;
  const x = c.getContext('2d')!;
  x.shadowColor = 'rgba(0,0,0,1)';
  x.shadowBlur = 22;
  x.fillStyle = '#000';
  x.beginPath();
  x.moveTo(40, 28);
  x.arcTo(100, 28, 100, 100, 20);
  x.arcTo(100, 100, 28, 100, 20);
  x.arcTo(28, 100, 28, 28, 20);
  x.arcTo(28, 28, 100, 28, 20);
  x.fill();
  shadowTex = new THREE.CanvasTexture(c);
  return shadowTex;
}

export interface PieceSpec {
  x: number;
  y: number;
  w: number;
  h: number;
  radius: number;
  bevel: number;
  backT: number;
  faceT: number;
  faceColor: number;
  backColor: number;
  /** Label canvas width in px; height follows the aspect ratio. */
  labelPx: number;
  sinkDepth: number;
  info: PressInfo | null;
  /** Label plane size as a fraction of the piece (tiles fill the face). */
  labelFit?: number;
  faceRough?: number;
}

export function makePiece(spec: PieceSpec): Piece {
  const group = new THREE.Group();
  group.position.set(spec.x, spec.y, 0);

  const back = new THREE.Mesh(cachedSlab(spec.w, spec.h, spec.radius, spec.backT, spec.bevel), glossy(spec.backColor, 0.25));
  const face = new THREE.Mesh(cachedSlab(spec.w, spec.h, spec.radius, spec.faceT, spec.bevel), glossy(spec.faceColor, spec.faceRough ?? 0.28));
  face.position.z = spec.backT;
  group.add(back, face);

  const lw = spec.labelPx;
  const lh = Math.max(16, Math.round((lw * spec.h) / spec.w));
  const cv = document.createElement('canvas');
  cv.width = lw;
  cv.height = lh;
  const tex = new THREE.CanvasTexture(cv);
  tex.anisotropy = 4;
  tex.colorSpace = THREE.SRGBColorSpace;
  const fit = spec.labelFit ?? 0.92;
  const mesh = new THREE.Mesh(
    new THREE.PlaneGeometry(spec.w * fit, spec.h * fit),
    new THREE.MeshBasicMaterial({ map: tex, transparent: true, toneMapped: false }),
  );
  mesh.position.z = spec.backT + spec.faceT + spec.bevel + 0.004;
  group.add(mesh);

  const shadow = new THREE.Mesh(
    new THREE.PlaneGeometry(spec.h * 1.67, spec.h * 1.67),
    new THREE.MeshBasicMaterial({ map: softSquare(), transparent: true, opacity: 0.5, depthWrite: false, toneMapped: false }),
  );
  shadow.renderOrder = 1;
  const shAsp = spec.w / spec.h;
  shadow.scale.x = shAsp;
  shadow.position.set(spec.x + 0.07, spec.y - 0.09, -0.045);

  const piece: Piece = {
    info: spec.info,
    group,
    back,
    face,
    lab: { ctx: cv.getContext('2d')!, tex, mesh, w: lw, h: lh },
    shadow,
    shAsp,
    homeX: spec.x,
    homeY: spec.y,
    lift: 0,
    target: 0,
    sink: 0,
    sinkT: 0,
    sinkDepth: spec.sinkDepth,
    sig: '',
    inT: 0,
    flipOut: 0,
    pulse: false,
    shake: 0,
    dim: false,
    overlay: false,
    ripple: 0,
  };
  back.userData.piece = piece;
  face.userData.piece = piece;
  return piece;
}
