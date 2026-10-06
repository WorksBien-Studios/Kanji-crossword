import { allPuzzles, type Puzzle } from './data';
import { Game } from './game';
import { chooseNext, recordPlayed, updateLevel } from './adaptive';
import { flushSave, saveSoon, type SaveData } from './save';
import type { PressInfo } from './view/pieces';
import type { GameView, ViewState } from './view/gameView';

const RESULT_DELAY_MS = 1600;

/** Wires the pure game state, the saved progress and the 3D view together. */
export class App {
  private puzzles = allPuzzles();
  private game!: Game;
  private seconds = 0;
  private paused = false;
  private lastTs = 0;
  private dirty = true;
  private shownSecond = -1;
  private winAt = 0;
  private result: { seconds: number; hintsUsed: number } | null = null;
  private tutorial: 0 | 1 | 2 = 0;
  private tutorialCell: { r: number; c: number } | null = null;
  private tutorialKanji: string | null = null;

  constructor(private view: GameView, private save: SaveData) {}

  start(forcePuzzle?: number): void {
    const resume = this.save.tutorialDone && this.save.current ? this.puzzles.find((p) => p.id === this.save.current!.id) : undefined;
    if (forcePuzzle !== undefined && this.puzzles[forcePuzzle]) {
      this.begin(this.puzzles[forcePuzzle]);
    } else if (!this.save.tutorialDone) {
      // Tutorial runs on the easiest puzzle in the library.
      const easiest = this.puzzles.slice().sort((a, b) => a.score - b.score)[0];
      this.begin(easiest);
    } else if (resume) {
      this.begin(resume, this.save.current!);
    } else {
      this.begin(chooseNext(this.puzzles, this.save.progress));
    }
  }

  private begin(puzzle: Puzzle, restore?: { filled: number[]; hintsUsed: number; history: number[]; seconds: number }): void {
    this.game = new Game(puzzle, restore);
    this.seconds = restore?.seconds ?? 0;
    this.winAt = 0;
    this.result = null;
    this.view.build(puzzle);
    if (!this.save.tutorialDone) this.startTutorial();
    else this.tutorial = 0;
    if (!restore) recordPlayed(this.save.progress, puzzle.id);
    this.persist();
    this.dirty = true;
  }

  private startTutorial(): void {
    const g = this.game;
    const n = g.nextOpen(0);
    if (n == null) { this.tutorial = 0; return; }
    const p = g.puzzle;
    let cell: { r: number; c: number } | null = null;
    for (let r = 0; r < p.rows && !cell; r++) for (let c = 0; c < p.cols; c++) if (p.num[r][c] === n) { cell = { r, c }; break; }
    this.tutorial = 1;
    this.tutorialCell = cell;
    this.tutorialKanji = p.solution[n];
    g.selected = null;
  }

  private persist(): void {
    const g = this.game;
    this.save.current = g.complete
      ? null
      : { id: g.puzzle.id, filled: [...g.filled], history: g.history.slice(), hintsUsed: g.hintsUsed, seconds: Math.round(this.seconds) };
    saveSoon(this.save);
  }

  pause(): void { this.paused = true; flushSave(); }
  resume(): void { this.paused = false; }

  press(info: PressInfo): void {
    const g = this.game;
    if (this.result) {
      if (info.kind === 'over') this.next();
      return;
    }
    if (g.complete) return;

    if (info.kind === 'hud') {
      g.restart();
      this.seconds = 0;
      if (!this.save.tutorialDone) this.startTutorial();
      this.touch();
      return;
    }
    if (this.tutorial === 1) {
      if (info.kind === 'tile' && this.tutorialCell && info.r === this.tutorialCell.r && info.c === this.tutorialCell.c) {
        g.select(info.n);
        this.tutorial = 2;
        this.touch();
      }
      return;
    }
    if (this.tutorial === 2) {
      if (info.kind === 'key' && info.kanji === this.tutorialKanji) {
        g.place(info.kanji);
        this.tutorial = 0;
        this.save.tutorialDone = true;
        this.afterMove();
      }
      return;
    }

    switch (info.kind) {
      case 'tile': g.select(info.n); break;
      case 'key': if (g.place(info.kanji) === 'wrong') this.view.shakeKey(info.kanji); break;
      case 'btn':
        if (info.name === 'undo') g.undo();
        else if (info.name === 'hint') g.hint();
        else g.skip();
        break;
      default: return;
    }
    this.afterMove();
  }

  private afterMove(): void {
    if (this.game.complete && !this.winAt) this.winAt = performance.now();
    this.persist();
    this.touch();
  }

  private touch(): void { this.dirty = true; }

  private finish(): void {
    const g = this.game;
    const slots = g.puzzle.count - g.puzzle.starters.length;
    const p = this.save.progress;
    if (this.save.tutorialDone) {
      // The tutorial solve does not move the skill level.
      p.level = updateLevel(p.level, { hintsUsed: g.hintsUsed, seconds: this.seconds, slots });
    }
    p.solved += 1;
    this.save.tutorialDone = true;
    this.save.current = null;
    saveSoon(this.save);
    this.result = { seconds: this.seconds, hintsUsed: g.hintsUsed };
    this.touch();
  }

  private next(): void {
    this.begin(chooseNext(this.puzzles, this.save.progress));
  }

  /** Called every animation frame. */
  frame(ts: number): void {
    const dt = this.lastTs ? Math.min(0.25, (ts - this.lastTs) / 1000) : 0;
    this.lastTs = ts;
    if (!this.paused && !this.game.complete) this.seconds += dt;
    if (this.winAt && !this.result && performance.now() - this.winAt > RESULT_DELAY_MS) this.finish();
    const sec = Math.floor(this.seconds);
    if (sec !== this.shownSecond) { this.shownSecond = sec; this.dirty = true; }
    if (this.dirty) {
      this.dirty = false;
      this.view.sync(this.viewState());
    }
    this.view.tick(ts);
  }

  viewState(): ViewState {
    const g = this.game;
    return {
      filled: g.filled,
      selected: g.selected,
      hintsLeft: g.hintsLeft,
      seconds: this.seconds,
      remaining: g.remaining,
      tutorial: this.tutorial,
      tutorialCell: this.tutorialCell,
      tutorialKanji: this.tutorialKanji,
      result: this.result,
      winAt: this.winAt,
    };
  }

  /** Debug helper for screenshots: fill every slot except `leave`. */
  debugFill(leave = 0): void {
    const g = this.game;
    this.tutorial = 0;
    this.save.tutorialDone = true;
    const open = [...Array(g.puzzle.count).keys()].map((i) => i + 1).filter((n) => !g.isFilled(n));
    for (const n of open.slice(0, open.length - leave)) { g.select(n); g.place(g.puzzle.solution[n]); }
    this.afterMove();
  }
}
