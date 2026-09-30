// Usage: node render.mjs  (needs playwright-core + system chromium; see fonts.css for fonts)
import { chromium } from 'playwright-core';
import { fileURLToPath } from 'url';
import path from 'path';
import fs from 'fs';
const here = path.dirname(fileURLToPath(import.meta.url));
const out = path.join(here, '..');
const names = { 1: '01-large-text-no-ads', 2: '02-tap-fills-same-number', 3: '03-completed-board-and-words' };
const devices = [
  { dir: 'iphone-6.9', d: 'iphone', w: 440, h: 956, dpr: 3 },   // 1320x2868
  { dir: 'ipad-13', d: 'ipad', w: 1032, h: 1376, dpr: 2 },      // 2064x2752
];
const browser = await chromium.launch({ executablePath: process.env.CHROMIUM || '/opt/pw-browsers/chromium' });
for (const dev of devices) {
  const ctx = await browser.newContext({ viewport: { width: dev.w, height: dev.h }, deviceScaleFactor: dev.dpr });
  fs.mkdirSync(path.join(out, dev.dir), { recursive: true });
  for (const s of [1, 2, 3]) {
    const page = await ctx.newPage();
    await page.goto(`file://${here}/mock.html?s=${s}&d=${dev.d}`);
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(out, dev.dir, `${names[s]}.png`) });
  }
}
await browser.close();
