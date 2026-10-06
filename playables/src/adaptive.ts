import type { Puzzle } from './data';

/**
 * Blended difficulty: the player never picks a level. A single skill value (0..1) moves a little
 * after each puzzle and decides how hard the next one is. Every few puzzles an easier "breather"
 * is mixed in so the climb feels gentle.
 */
export interface Progress {
  level: number;
  played: string[];
  solved: number;
}

export const START_LEVEL = 0.12;
const PLAYED_CAP = 400;

export interface SolveResult {
  hintsUsed: number;
  seconds: number;
  /** Slots the player had to fill (excludes starters). */
  slots: number;
}

/** Roughly how long a comfortable solve takes. */
export function expectedSeconds(slots: number): number {
  return 25 + slots * 12;
}

export function updateLevel(level: number, r: SolveResult): number {
  const speed = r.seconds / expectedSeconds(r.slots);
  let delta = 0;
  if (r.hintsUsed === 0 && speed <= 1) delta = 0.07;
  else if (r.hintsUsed === 0) delta = speed > 2.2 ? -0.03 : 0.03;
  else if (r.hintsUsed === 1) delta = speed > 1.8 ? -0.04 : 0;
  else delta = -0.07;
  return Math.min(1, Math.max(0, level + delta));
}

/** Maps a skill level onto the actual score range found in the library. */
export function levelToScore(level: number, lo: number, hi: number): number {
  return lo + (hi - lo) * level;
}

export function scoreRange(puzzles: Puzzle[]): [number, number] {
  const scores = puzzles.map((p) => p.score).sort((a, b) => a - b);
  const at = (q: number) => scores[Math.min(scores.length - 1, Math.max(0, Math.round(q * (scores.length - 1))))];
  return [at(0.02), at(0.98)];
}

/** Picks the next puzzle. `rand` is injectable so the choice is testable. */
export function chooseNext(puzzles: Puzzle[], progress: Progress, rand: () => number = Math.random): Puzzle {
  const [lo, hi] = scoreRange(puzzles);
  const breather = progress.solved > 0 && progress.solved % 4 === 3;
  const level = Math.max(0, progress.level - (breather ? 0.18 : 0));
  const target = levelToScore(level, lo, hi);
  const seen = new Set(progress.played);
  let pool = puzzles.filter((p) => !seen.has(p.id));
  if (pool.length === 0) pool = puzzles;
  const ranked = pool.slice().sort((a, b) => Math.abs(a.score - target) - Math.abs(b.score - target));
  const top = ranked.slice(0, Math.min(5, ranked.length));
  return top[Math.floor(rand() * top.length)];
}

export function recordPlayed(progress: Progress, id: string): void {
  progress.played.push(id);
  if (progress.played.length > PLAYED_CAP) progress.played.splice(0, progress.played.length - PLAYED_CAP);
}
