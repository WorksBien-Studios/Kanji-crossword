import { sdk } from './sdk';
import { START_LEVEL, type Progress } from './adaptive';

export interface SavedCurrent {
  id: string;
  filled: number[];
  history: number[];
  hintsUsed: number;
  seconds: number;
}

export interface SaveData {
  v: 1;
  progress: Progress;
  tutorialDone: boolean;
  current: SavedCurrent | null;
}

export function freshSave(): SaveData {
  return { v: 1, progress: { level: START_LEVEL, played: [], solved: 0 }, tutorialDone: false, current: null };
}

export function parseSave(text: string | null | undefined): SaveData {
  if (!text) return freshSave();
  try {
    const d = JSON.parse(text);
    if (d && d.v === 1 && d.progress && Array.isArray(d.progress.played)) return d as SaveData;
  } catch {
    /* fall through to a fresh save */
  }
  return freshSave();
}

export async function loadSave(): Promise<SaveData> {
  return parseSave(await sdk.loadData());
}

let pending: SaveData | null = null;
let timer: number | undefined;

/** Debounced so a burst of moves costs one write. */
export function saveSoon(data: SaveData): void {
  pending = data;
  if (timer !== undefined) return;
  timer = window.setTimeout(flushSave, 400);
}

export function flushSave(): void {
  if (timer !== undefined) window.clearTimeout(timer);
  timer = undefined;
  if (pending) void sdk.saveData(JSON.stringify(pending));
  pending = null;
}
