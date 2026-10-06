import raw from './generated/puzzles.json';

/** Compact record produced by scripts/build-puzzles.mjs. */
interface RawPuzzle {
  id: string;
  d: string;
  s: number;
  r: number;
  c: number;
  g: string[];
  n: Record<string, number>;
  k: Record<string, string>;
  st: number[];
  t: string[];
}

export interface Puzzle {
  id: string;
  difficulty: string;
  /** Solver-derived difficulty (0..1) from engine/difficulty.py. */
  score: number;
  rows: number;
  cols: number;
  /** open[r][c] is true for fillable cells. */
  open: boolean[][];
  /** num[r][c] is the kanji slot number (1..count) or 0 for a block. */
  num: number[][];
  /** solution[n] is the kanji for slot n (index 0 unused). */
  solution: string[];
  /** Slots already filled when the puzzle starts. */
  starters: number[];
  /** Shuffled kanji shown in the tray. */
  tray: string[];
  /** Number of distinct kanji slots. */
  count: number;
}

export function parsePuzzle(p: RawPuzzle): Puzzle {
  const open = p.g.map((row) => Array.from(row).map((ch) => ch !== '#'));
  const num = p.g.map((row, r) => Array.from(row).map((_, c) => p.n[`${r},${c}`] ?? 0));
  const count = Object.keys(p.k).length;
  const solution: string[] = new Array(count + 1).fill('');
  for (const [n, kanji] of Object.entries(p.k)) solution[Number(n)] = kanji;
  return { id: p.id, difficulty: p.d, score: p.s, rows: p.r, cols: p.c, open, num, solution, starters: p.st.slice(), tray: p.t.slice(), count };
}

let cache: Puzzle[] | null = null;
export function allPuzzles(): Puzzle[] {
  if (!cache) cache = (raw as unknown as RawPuzzle[]).map(parsePuzzle);
  return cache;
}
