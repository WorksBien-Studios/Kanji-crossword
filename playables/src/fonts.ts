// Fonts are bundled so every device draws the same glyphs (the canvas would otherwise fall back to
// whatever Japanese font the device has). Both are SIL OFL 1.1; see src/assets/fonts/OFL-*.txt.
import minchoUrl from './assets/fonts/shippori-mincho-800.woff2?url';
import figtreeUrl from './assets/fonts/figtree-800.woff2?url';

/** Loads both faces before anything is painted. Never throws: the font stacks keep system fallbacks. */
export async function loadFonts(timeoutMs = 4000): Promise<boolean> {
  try {
    const faces = [
      new FontFace('Shippori Mincho', `url(${minchoUrl}) format("woff2")`, { weight: '800' }),
      new FontFace('Figtree', `url(${figtreeUrl}) format("woff2")`, { weight: '800' }),
    ];
    const all = Promise.all(faces.map((f) => f.load())).then((loaded) => {
      loaded.forEach((f) => document.fonts.add(f));
      return true;
    });
    return await Promise.race([all, new Promise<boolean>((r) => setTimeout(() => r(false), timeoutMs))]);
  } catch {
    return false;
  }
}
