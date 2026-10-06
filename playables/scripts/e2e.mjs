// End-to-end check in headless Chromium: real pointer taps through the raycaster.
// Usage: npm run build && node scripts/e2e.mjs
import { chromium } from 'playwright-core';
import { spawn } from 'node:child_process';
import { readdirSync, existsSync } from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const base = process.env.PLAYWRIGHT_BROWSERS_PATH || '/opt/pw-browsers';
const chrome = readdirSync(base).filter((n) => n.startsWith('chromium-')).map((d) => join(base, d, 'chrome-linux', 'chrome')).find(existsSync);
const port = 4175;
const server = spawn('npx', ['vite', 'preview', '--port', String(port), '--strictPort'], { cwd: root, stdio: 'ignore' });
await new Promise((r) => setTimeout(r, 2500));
const browser = await chromium.launch({ executablePath: chrome, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'] });

let failed = 0;
const check = (name, ok, extra = '') => { console.log(`${ok ? 'PASS' : 'FAIL'}  ${name} ${extra}`); if (!ok) failed++; };

const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
await page.goto(`http://localhost:${port}/`);
await page.waitForTimeout(1500);

// Screen position of a piece, via the live camera.
const screenOf = (sel) => page.evaluate((sel) => {
  const app = window.__game, v = app.view;
  const piece = sel.kind === 'tile' ? v.tiles.find((t) => t.info.r === sel.r && t.info.c === sel.c)
    : sel.kind === 'key' ? v.keys.find((k) => k.kanji === sel.kanji)
    : sel.kind === 'btn' ? v.btns.find((b) => b.info.name === sel.name)
    : sel.kind === 'over' ? v.over.find((o) => o.info)
    : v.hud.reset;
  const p = piece.group.position.clone();
  v.stage.world.updateMatrixWorld(true);
  p.applyMatrix4(v.stage.world.matrixWorld).project(v.stage.camera);
  return { x: (p.x + 1) / 2 * innerWidth, y: (1 - p.y) / 2 * innerHeight };
}, sel);
const state = () => page.evaluate(() => { const a = window.__game, s = a.viewState(); return { tut: s.tutorial, cell: s.tutorialCell, kanji: s.tutorialKanji, filled: s.filled.size, sel: s.selected, hints: s.hintsLeft, rem: s.remaining, result: !!s.result, id: a.game.puzzle.id }; });
const tap = async (sel) => { const p = await screenOf(sel); await page.mouse.click(p.x, p.y); await page.waitForTimeout(250); };

let s = await state();
check('starts in tutorial step 1', s.tut === 1 && !!s.cell);
const startFilled = s.filled;

// Wrong targets are ignored during the tutorial.
await tap({ kind: 'key', kanji: s.kanji });
check('key ignored in step 1', (await state()).tut === 1);

await tap({ kind: 'tile', ...s.cell });
s = await state();
check('tapping the highlighted tile advances to step 2', s.tut === 2 && s.sel !== null);
const wrongKey = await page.evaluate((k) => window.__game.view.keys.find((x) => x.kanji !== k && x.info).kanji, s.kanji);
await tap({ kind: 'key', kanji: wrongKey });
check('wrong key ignored in step 2', (await state()).tut === 2);
await tap({ kind: 'key', kanji: s.kanji });
s = await state();
check('tapping the highlighted key fills the slot and ends the tutorial', s.tut === 0 && s.filled === startFilled + 1);

// Normal play: select a tile, wrong key does not fill, hint fills, undo restores.
const open = await page.evaluate(() => { const g = window.__game.game; const n = g.nextOpen(0); const p = g.puzzle; for (let r = 0; r < p.rows; r++) for (let c = 0; c < p.cols; c++) if (p.num[r][c] === n) return { n, r, c, kanji: p.solution[n] }; });
await tap({ kind: 'tile', r: open.r, c: open.c });
check('tap selects a tile', (await state()).sel === open.n);
const wrong2 = await page.evaluate((k) => window.__game.view.keys.find((x) => x.kanji !== k && !window.__game.game.isFilled(window.__game.view.kanjiToN.get(x.kanji))).kanji, open.kanji);
const before = (await state()).filled;
await tap({ kind: 'key', kanji: wrong2 });
check('wrong kanji is rejected', (await state()).filled === before);
await tap({ kind: 'btn', name: 'hint' });
s = await state();
check('hint fills a slot and costs one hint', s.filled === before + 1 && s.hints === 1);
await tap({ kind: 'btn', name: 'undo' });
check('undo takes the slot back', (await state()).filled === before);

// Solve the rest by tapping, then check the completion flow.
for (let guard = 0; guard < 40; guard++) {
  const t = await page.evaluate(() => { const g = window.__game.game; if (g.complete) return null; const n = g.selected ?? g.nextOpen(0); const p = g.puzzle; for (let r = 0; r < p.rows; r++) for (let c = 0; c < p.cols; c++) if (p.num[r][c] === n) return { n, r, c, kanji: p.solution[n] }; });
  if (!t) break;
  await tap({ kind: 'tile', r: t.r, c: t.c });
  await tap({ kind: 'key', kanji: t.kanji });
}
s = await state();
check('puzzle completes by tapping', s.rem === 0);
await page.waitForTimeout(5200);
s = await state();
check('result appears after the ripple', s.result);
const oldId = s.id;
await tap({ kind: 'over' });
await page.waitForTimeout(500);
s = await state();
check('play bar loads a new puzzle', !s.result && s.id !== oldId && s.rem > 0);
check('new puzzle is not the tutorial', s.tut === 0);
check('no page errors', errors.length === 0, errors.slice(0, 2).join(' | '));

await browser.close();
server.kill();
process.exit(failed ? 1 : 0);
