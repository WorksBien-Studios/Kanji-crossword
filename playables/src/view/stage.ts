import * as THREE from 'three';
import { CONTENT_Z_MAX, CONTENT_Z_MIN, FOV, makeFitInput, fitCamera, readSafeInsets, type ContentBox, type FitResult } from './fit';

// The approved mockup was tuned on an older Three.js that did not convert colours between colour
// spaces and used legacy light units. Keep that behaviour so the look carries over unchanged.
THREE.ColorManagement.enabled = false;

function rng(seed: number): () => number {
  let a = seed | 0;
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function canvas2d(w: number, h: number): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  return [c, c.getContext('2d')!];
}

/** Terrazzo drawn in code, so the table costs no download. 1024px covers 8 world units. */
function terrazzoTexture(): THREE.CanvasTexture {
  const [c, x] = canvas2d(1024, 1024);
  const r = rng(41);
  const cols = ['#c9a9a0', '#8fa8a0', '#d9b36c', '#7d8a99', '#f6f2ea', '#b86f5a', '#5f6f66'];
  x.fillStyle = '#e4e0d8';
  x.fillRect(0, 0, 1024, 1024);
  for (let i = 0; i < 1300; i++) {
    const cx = r() * 1024;
    const cy = r() * 1024;
    const rad = 3 + Math.pow(r(), 2.2) * 24;
    const n = 5 + Math.floor(r() * 3);
    x.fillStyle = cols[Math.floor(r() * cols.length)];
    const pts: [number, number][] = [];
    for (let k = 0; k < n; k++) {
      const a = (k / n) * 6.283 + r() * 0.6;
      const rr = rad * (0.65 + r() * 0.5);
      pts.push([Math.cos(a) * rr, Math.sin(a) * rr]);
    }
    // Draw wrapped copies near an edge so the texture tiles without seams.
    for (const dx of [-1024, 0, 1024]) {
      for (const dy of [-1024, 0, 1024]) {
        const ox = cx + dx;
        const oy = cy + dy;
        if (ox < -rad * 2 || ox > 1024 + rad * 2 || oy < -rad * 2 || oy > 1024 + rad * 2) continue;
        x.beginPath();
        pts.forEach(([px, py], k) => (k ? x.lineTo(ox + px, oy + py) : x.moveTo(ox + px, oy + py)));
        x.closePath();
        x.fill();
      }
    }
  }
  for (let i = 0; i < 5000; i++) {
    x.fillStyle = `rgba(60,60,60,${0.05 + r() * 0.1})`;
    x.fillRect(r() * 1024, r() * 1024, 1.4, 1.4);
  }
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = 8;
  t.wrapS = t.wrapT = THREE.RepeatWrapping;
  return t;
}

function softShadowTexture(): THREE.CanvasTexture {
  const [c, x] = canvas2d(256, 256);
  const g = x.createRadialGradient(128, 128, 10, 128, 128, 128);
  g.addColorStop(0, 'rgba(0,0,0,.6)');
  g.addColorStop(1, 'rgba(0,0,0,0)');
  x.fillStyle = g;
  x.fillRect(0, 0, 256, 256);
  return new THREE.CanvasTexture(c);
}

function sheenTexture(): THREE.CanvasTexture {
  const [c, x] = canvas2d(256, 256);
  const g = x.createRadialGradient(128, 128, 0, 128, 128, 128);
  g.addColorStop(0, 'rgba(255,255,255,.9)');
  g.addColorStop(1, 'rgba(255,255,255,0)');
  x.fillStyle = g;
  x.fillRect(0, 0, 256, 256);
  return new THREE.CanvasTexture(c);
}

export const TABLE_Z = -0.27;
const MAX_DEVICE_PIXELS = 3_200_000;
const TAN = Math.tan((FOV * Math.PI) / 360);

export class Stage {
  readonly renderer: THREE.WebGLRenderer;
  readonly scene = new THREE.Scene();
  readonly camera = new THREE.PerspectiveCamera(FOV, 0.58, 0.1, 80);
  /** Everything that tilts with the pointer lives in here. */
  readonly world = new THREE.Group();
  private table: THREE.Mesh;
  private tex: THREE.CanvasTexture;
  private bigShadow: THREE.Mesh;
  private tw = 8;
  private content: ContentBox = { halfWidth: 3, top: 7, bottom: -7, zMin: CONTENT_Z_MIN, zMax: CONTENT_Z_MAX };
  fit: FitResult | null = null;
  /** Pixels per world unit at the board plane; used for tap-size reasoning and tests. */
  ppu = 50;

  constructor(readonly canvas: HTMLCanvasElement) {
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.05;

    // Studio environment: a dark room with softboxes for the lacquer to reflect.
    const env = new THREE.Scene();
    env.add(new THREE.Mesh(new THREE.SphereGeometry(40, 24, 16), new THREE.MeshBasicMaterial({ color: 0x1b2c36, side: THREE.BackSide })));
    const box = (w: number, h: number, x: number, y: number, z: number, color: number, i: number) => {
      const m = new THREE.Mesh(
        new THREE.PlaneGeometry(w, h),
        new THREE.MeshBasicMaterial({ color: new THREE.Color(color).multiplyScalar(i), side: THREE.DoubleSide }),
      );
      m.position.set(x, y, z);
      m.lookAt(0, 0, 0);
      env.add(m);
    };
    box(30, 14, 0, 28, 10, 0xffffff, 7);
    box(8, 26, -26, 4, 8, 0xffe2b8, 5);
    box(8, 26, 26, 2, 8, 0xbfe2ff, 4);
    box(40, 6, 0, -20, 14, 0xffffff, 1.2);
    const pmrem = new THREE.PMREMGenerator(this.renderer);
    this.scene.environment = pmrem.fromScene(env, 0.03).texture;
    pmrem.dispose();

    // Mockup used intensity 0.5 on legacy units; physical units need a factor of pi.
    const sun = new THREE.DirectionalLight(0xffffff, 0.5 * Math.PI);
    sun.position.set(-3, 5, 8);
    this.scene.add(sun);

    this.scene.add(this.world);

    this.tex = terrazzoTexture();
    this.table = new THREE.Mesh(
      new THREE.PlaneGeometry(1, 1),
      new THREE.MeshPhysicalMaterial({ map: this.tex, roughness: 0.22, metalness: 0, clearcoat: 0.8, clearcoatRoughness: 0.12, envMapIntensity: 0.6 }),
    );
    this.table.position.z = TABLE_Z;
    this.world.add(this.table);

    const sheen = new THREE.Mesh(
      new THREE.PlaneGeometry(13, 13),
      new THREE.MeshBasicMaterial({ map: sheenTexture(), transparent: true, opacity: 0.2, blending: THREE.AdditiveBlending, depthWrite: false, toneMapped: false }),
    );
    sheen.position.set(-2.2, 4.4, TABLE_Z + 0.002);
    this.world.add(sheen);

    this.bigShadow = new THREE.Mesh(
      new THREE.PlaneGeometry(9.4, 15.5),
      new THREE.MeshBasicMaterial({ map: softShadowTexture(), transparent: true, opacity: 0.36, depthWrite: false }),
    );
    this.bigShadow.position.z = TABLE_Z + 0.008;
    this.world.add(this.bigShadow);
  }

  /** Tells the stage how much room the layout needs, then refits the camera. */
  setContent(c: { halfWidth: number; top: number; bottom: number }): void {
    this.content = { ...c, zMin: CONTENT_Z_MIN, zMax: CONTENT_Z_MAX };
    this.bigShadow.position.y = (c.top + c.bottom) / 2;
    this.bigShadow.scale.set((c.halfWidth * 2 + 3.5) / 9.4, (c.top - c.bottom + 2.5) / 15.5, 1);
    this.resize();
  }

  resize(): void {
    const w = window.innerWidth;
    const h = window.innerHeight;
    if (!w || !h) return;
    // Cap the pixel count so very large or very dense screens stay smooth.
    let dpr = Math.min(window.devicePixelRatio || 1, 2);
    while (w * h * dpr * dpr > MAX_DEVICE_PIXELS && dpr > 1) dpr = Math.max(1, dpr - 0.25);
    this.renderer.setPixelRatio(dpr);
    this.renderer.setSize(w, h, false);
    this.camera.aspect = w / h;

    const fit = fitCamera(makeFitInput(w, h, readSafeInsets(), this.content));
    this.fit = fit;
    this.camera.position.set(0, 0, fit.distance);
    this.camera.updateProjectionMatrix();
    this.ppu = fit.ppu;
    this.world.position.y = fit.worldY;

    // The table must cover the whole screen at any tilt, so make it generously large.
    const vh = 2 * TAN * (fit.distance + 0.3);
    const size = Math.max(vh * this.camera.aspect, vh) * 1.7 + Math.abs(fit.worldY) * 2;
    this.table.scale.set(size, size, 1);
    this.table.position.y = -fit.worldY;
    this.tex.repeat.set(size / this.tw, size / this.tw);
  }

  render(): void {
    this.renderer.render(this.scene, this.camera);
  }
}
