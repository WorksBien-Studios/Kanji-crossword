import type { Puzzle } from './data';

export const HINTS_PER_PUZZLE = 2;

export type PlaceResult = 'ok' | 'wrong' | 'none';

/** Pure puzzle state. No rendering, timers or storage in here. */
export class Game {
  readonly puzzle: Puzzle;
  filled = new Set<number>();
  selected: number | null = null;
  hintsUsed = 0;
  /** Slots placed by the player, newest last (starters are not undoable). */
  history: number[] = [];

  constructor(puzzle: Puzzle, restore?: { filled: number[]; hintsUsed: number; history: number[] }) {
    this.puzzle = puzzle;
    for (const n of puzzle.starters) this.filled.add(n);
    if (restore) {
      for (const n of restore.filled) this.filled.add(n);
      this.hintsUsed = restore.hintsUsed;
      this.history = restore.history.filter((n) => this.filled.has(n));
    }
  }

  get hintsLeft(): number {
    return Math.max(0, HINTS_PER_PUZZLE - this.hintsUsed);
  }

  get remaining(): number {
    return this.puzzle.count - this.filled.size;
  }

  get complete(): boolean {
    return this.remaining === 0;
  }

  isFilled(n: number): boolean {
    return this.filled.has(n);
  }

  /** Next open slot after `from` (wrapping), or null when everything is filled. */
  nextOpen(from: number): number | null {
    const total = this.puzzle.count;
    for (let i = 1; i <= total; i++) {
      const n = ((from + i - 1) % total) + 1;
      if (!this.filled.has(n)) return n;
    }
    return null;
  }

  select(n: number): void {
    if (n >= 1 && n <= this.puzzle.count && !this.filled.has(n)) this.selected = n;
  }

  private commit(n: number): void {
    this.filled.add(n);
    this.history.push(n);
    this.selected = this.nextOpen(n);
  }

  /** Player picks a kanji from the tray for the selected slot. */
  place(kanji: string): PlaceResult {
    const n = this.selected;
    if (n == null) return 'none';
    if (this.puzzle.solution[n] !== kanji) return 'wrong';
    this.commit(n);
    return 'ok';
  }

  hint(): boolean {
    if (this.selected == null || this.hintsLeft === 0) return false;
    this.hintsUsed++;
    this.commit(this.selected);
    return true;
  }

  undo(): boolean {
    const n = this.history.pop();
    if (n == null) return false;
    this.filled.delete(n);
    this.selected = n;
    return true;
  }

  skip(): void {
    if (this.selected != null) this.selected = this.nextOpen(this.selected);
    else this.selected = this.nextOpen(0);
  }

  /** Back to the starting position of this puzzle. */
  restart(): void {
    this.filled = new Set(this.puzzle.starters);
    this.history = [];
    this.hintsUsed = 0;
    this.selected = null;
  }
}
