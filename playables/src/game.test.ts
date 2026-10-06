import { describe, expect, it } from 'vitest';
import { allPuzzles } from './data';
import { Game, HINTS_PER_PUZZLE } from './game';
import { chooseNext, START_LEVEL, updateLevel, scoreRange, type Progress } from './adaptive';
import { parseSave } from './save';

const puzzles = allPuzzles();

describe('library', () => {
  it('loads every standard puzzle with consistent numbering', () => {
    expect(puzzles.length).toBe(240);
    for (const p of puzzles) {
      const nums = new Set<number>();
      p.num.forEach((row, r) => row.forEach((n, c) => { if (n) { nums.add(n); expect(p.open[r][c]).toBe(true); } }));
      expect(nums.size).toBe(p.count);
      expect(p.tray.length).toBe(p.count);
      expect(new Set(p.tray)).toEqual(new Set(p.solution.slice(1)));
    }
  });
});

describe('Game', () => {
  const p = puzzles[0];
  it('starts with the starter cells filled', () => {
    const g = new Game(p);
    for (const n of p.starters) expect(g.isFilled(n)).toBe(true);
    expect(g.remaining).toBe(p.count - p.starters.length);
  });
  it('rejects a wrong kanji and accepts the right one', () => {
    const g = new Game(p);
    const n = g.nextOpen(0)!;
    g.select(n);
    const wrong = p.tray.find((k) => k !== p.solution[n])!;
    expect(g.place(wrong)).toBe('wrong');
    expect(g.isFilled(n)).toBe(false);
    expect(g.place(p.solution[n])).toBe('ok');
    expect(g.isFilled(n)).toBe(true);
  });
  it('undo restores the slot and reselects it', () => {
    const g = new Game(p);
    const n = g.nextOpen(0)!;
    g.select(n);
    g.place(p.solution[n]);
    expect(g.undo()).toBe(true);
    expect(g.isFilled(n)).toBe(false);
    expect(g.selected).toBe(n);
    expect(g.undo()).toBe(false);
  });
  it('limits hints', () => {
    const g = new Game(p);
    for (let i = 0; i < HINTS_PER_PUZZLE; i++) { g.select(g.nextOpen(0)!); expect(g.hint()).toBe(true); }
    g.select(g.nextOpen(0)!);
    expect(g.hint()).toBe(false);
    expect(g.hintsLeft).toBe(0);
  });
  it('can be solved to completion', () => {
    const g = new Game(p);
    while (!g.complete) { const n = g.nextOpen(0)!; g.select(n); expect(g.place(p.solution[n])).toBe('ok'); }
    expect(g.complete).toBe(true);
  });
});

describe('adaptive difficulty', () => {
  it('raises the level on fast clean solves and lowers it after hint-heavy ones', () => {
    expect(updateLevel(0.5, { hintsUsed: 0, seconds: 20, slots: 15 })).toBeGreaterThan(0.5);
    expect(updateLevel(0.5, { hintsUsed: 2, seconds: 400, slots: 15 })).toBeLessThan(0.5);
    expect(updateLevel(0, { hintsUsed: 3, seconds: 900, slots: 15 })).toBe(0);
    expect(updateLevel(1, { hintsUsed: 0, seconds: 5, slots: 15 })).toBe(1);
  });
  it('chooses harder puzzles at higher levels and never repeats until the pool is empty', () => {
    const [lo, hi] = scoreRange(puzzles);
    expect(hi).toBeGreaterThan(lo);
    const first = (level: number) => chooseNext(puzzles, { level, played: [], solved: 0 }, () => 0);
    expect(first(0.9).score).toBeGreaterThan(first(0.1).score);
    const prog: Progress = { level: START_LEVEL, played: [], solved: 0 };
    const seen = new Set<string>();
    for (let i = 0; i < 40; i++) {
      const next = chooseNext(puzzles, prog);
      expect(seen.has(next.id)).toBe(false);
      seen.add(next.id);
      prog.played.push(next.id);
      prog.solved++;
    }
  });
  it('mixes in an easier breather every fourth puzzle', () => {
    const base: Progress = { level: 0.8, played: [], solved: 0 };
    const normal = chooseNext(puzzles, base, () => 0).score;
    const breather = chooseNext(puzzles, { ...base, solved: 3 }, () => 0).score;
    expect(breather).toBeLessThan(normal);
  });
});

describe('save', () => {
  it('falls back to a fresh save for bad data', () => {
    expect(parseSave('not json').progress.level).toBe(START_LEVEL);
    expect(parseSave(null).tutorialDone).toBe(false);
    expect(parseSave(JSON.stringify({ v: 1, progress: { level: 0.4, played: ['a'], solved: 2 }, tutorialDone: true, current: null })).progress.level).toBe(0.4);
  });
});
