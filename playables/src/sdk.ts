/**
 * Thin wrapper over the YouTube Playables SDK.
 *
 * UNVERIFIED: written from memory of the public API (ytgame.game.firstFrameReady, gameReady,
 * saveData, loadData; ytgame.system.onPause, onResume). The docs site was not reachable while this
 * was written, so every call is optional-chained and guarded. Check names against the current
 * Playables documentation before submitting.
 *
 * When the SDK is absent (local dev) the wrapper degrades to no-ops and localStorage.
 */
interface YtGame {
  game?: {
    firstFrameReady?: () => void;
    gameReady?: () => void;
    saveData?: (data: string) => Promise<void>;
    loadData?: () => Promise<string>;
  };
  system?: {
    onPause?: (cb: () => void) => void;
    onResume?: (cb: () => void) => void;
  };
}

const yt = (): YtGame | undefined => (window as unknown as { ytgame?: YtGame }).ytgame;
const KEY = 'kanji-tiles-save';

export const sdk = {
  get available(): boolean {
    return !!yt();
  },
  firstFrameReady(): void {
    try { yt()?.game?.firstFrameReady?.(); } catch { /* ignore */ }
  },
  gameReady(): void {
    try { yt()?.game?.gameReady?.(); } catch { /* ignore */ }
  },
  async loadData(): Promise<string | null> {
    try {
      const f = yt()?.game?.loadData;
      if (f) return (await f()) || null;
    } catch { /* fall back */ }
    try { return localStorage.getItem(KEY); } catch { return null; }
  },
  async saveData(data: string): Promise<void> {
    try {
      const f = yt()?.game?.saveData;
      if (f) { await f(data); return; }
    } catch { /* fall back */ }
    try { localStorage.setItem(KEY, data); } catch { /* ignore */ }
  },
  onPause(cb: () => void): void {
    try { yt()?.system?.onPause?.(cb); } catch { /* ignore */ }
    document.addEventListener('visibilitychange', () => { if (document.hidden) cb(); });
  },
  onResume(cb: () => void): void {
    try { yt()?.system?.onResume?.(cb); } catch { /* ignore */ }
    document.addEventListener('visibilitychange', () => { if (!document.hidden) cb(); });
  },
};
