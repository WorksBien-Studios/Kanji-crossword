import { fitCamera, makeFitInput, type Insets } from './fit';
import { computeLayout, contentBox, type Mode } from './layout';

/** Fit of the (identical for every puzzle) 5x5 / 8-key layout in each arrangement. */
export function fitsByMode(w: number, h: number, insets: Insets): Record<Mode, { ppu: number }> {
  const one = (mode: Mode) => fitCamera(makeFitInput(w, h, insets, contentBox(computeLayout(5, 5, 8, mode))));
  return { portrait: one('portrait'), landscape: one('landscape') };
}

/**
 * Picks the arrangement that gives the larger on-screen scale for this exact screen. A 4% margin
 * stops it flipping back and forth while a window is dragged near the crossover.
 */
export function bestMode(w: number, h: number, insets: Insets, current?: Mode): Mode {
  const f = fitsByMode(w, h, insets);
  const better: Mode = f.landscape.ppu > f.portrait.ppu ? 'landscape' : 'portrait';
  if (!current || current === better) return better;
  const ratio = f[better].ppu / f[current].ppu;
  return ratio > 1.04 ? better : current;
}
