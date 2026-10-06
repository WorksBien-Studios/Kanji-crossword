import * as THREE from 'three';

export function roundedShape(w: number, h: number, r: number): THREE.Shape {
  const s = new THREE.Shape();
  const x = -w / 2;
  const y = -h / 2;
  s.moveTo(x + r, y);
  s.lineTo(x + w - r, y);
  s.quadraticCurveTo(x + w, y, x + w, y + r);
  s.lineTo(x + w, y + h - r);
  s.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  s.lineTo(x + r, y + h);
  s.quadraticCurveTo(x, y + h, x, y + h - r);
  s.lineTo(x, y + r);
  s.quadraticCurveTo(x, y, x + r, y);
  return s;
}

/** Rounded slab with a bevel; its top face sits at z = depth + bevel. */
export function slab(w: number, h: number, r: number, depth: number, bevel: number, segments = 5): THREE.ExtrudeGeometry {
  return new THREE.ExtrudeGeometry(roundedShape(w, h, Math.min(r, Math.min(w, h) / 2 - 0.001)), {
    depth,
    bevelEnabled: true,
    bevelSize: bevel,
    bevelThickness: bevel,
    bevelSegments: segments,
    curveSegments: 10,
  });
}

export function glossy(color: number, roughness: number, envMapIntensity = 1.15): THREE.MeshPhysicalMaterial {
  return new THREE.MeshPhysicalMaterial({
    color,
    roughness,
    metalness: 0,
    clearcoat: 1,
    clearcoatRoughness: 0.04,
    envMapIntensity,
    emissive: 0x000000,
  });
}

export function shade(hex: number, f: number): THREE.Color {
  return new THREE.Color(hex).multiplyScalar(f);
}

export function disposeObject(o: THREE.Object3D): void {
  o.traverse((c) => {
    const m = c as THREE.Mesh;
    if (!m.isMesh) return;
    m.geometry?.dispose?.();
    const mat = m.material as THREE.Material | THREE.Material[];
    for (const mm of Array.isArray(mat) ? mat : [mat]) {
      (mm as THREE.MeshBasicMaterial).map?.dispose?.();
      mm.dispose();
    }
  });
}
