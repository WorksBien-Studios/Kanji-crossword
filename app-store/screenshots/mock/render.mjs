// Usage: node render.mjs  (needs playwright-core + system chromium; see fonts.css for fonts)
import { chromium } from 'playwright-core';
import { fileURLToPath } from 'url';
import path from 'path';
const here = path.dirname(fileURLToPath(import.meta.url));
const out = path.join(here, '..');
const names = { 1: '01-large-text-no-ads', 2: '02-tap-fills-same-number', 3: '03-completed-board-and-words' };
const browser = await chromium.launch({ executablePath: process.env.CHROMIUM || '/opt/pw-browsers/chromium' });
// 440x956 CSS px @3x = 1320x2868 (iPhone 6.9")
const ctx = await browser.newContext({ viewport: { width: 440, height: 956 }, deviceScaleFactor: 3 });
for (const s of [1, 2, 3]) {
  const page = await ctx.newPage();
  await page.goto(`file://${here}/mock.html?s=${s}`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(out, `${names[s]}.png`) });
}
await browser.close();
