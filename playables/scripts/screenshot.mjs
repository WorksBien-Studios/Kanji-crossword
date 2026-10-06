// Renders the built game in headless Chromium (software GL) and saves screenshots to ./shots.
// Usage: npm run build && npm run shot
import { chromium } from 'playwright-core';
import { spawn } from 'node:child_process';
import { mkdirSync, readdirSync, existsSync } from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const outDir = join(root, 'shots');
mkdirSync(outDir, { recursive: true });

function findChrome() {
  const base = process.env.PLAYWRIGHT_BROWSERS_PATH || '/opt/pw-browsers';
  for (const d of readdirSync(base).filter((n) => n.startsWith('chromium-')).sort().reverse()) {
    const p = join(base, d, 'chrome-linux', 'chrome');
    if (existsSync(p)) return p;
  }
  return undefined;
}

const port = 4173;
const server = spawn('npx', ['vite', 'preview', '--port', String(port), '--strictPort'], { cwd: root, stdio: 'ignore' });
await new Promise((r) => setTimeout(r, 2500));

const browser = await chromium.launch({
  executablePath: findChrome(),
  args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--no-sandbox'],
});

const sizes = { phone: { width: 390, height: 844 }, landscape: { width: 844, height: 390 }, laptop: { width: 1280, height: 720 }, small: { width: 320, height: 568 } };
const shots = [
  { name: 'tutorial-1', query: '', wait: 1800 },
  { name: 'board', query: '?tut=0&p=40', wait: 1800 },
  { name: 'complete', query: '?tut=0&p=40&done=1', wait: 6500 },
];
for (const [sizeName, viewport] of Object.entries(sizes)) {
  for (const s of shots) {
    if (sizeName !== 'phone' && s.name === 'tutorial-1') continue;
    const page = await browser.newPage({ viewport, deviceScaleFactor: sizeName === 'phone' || sizeName === 'small' ? 2 : 1 });
    const logs = [];
    page.on('console', (m) => { if (m.type() === 'error' || m.type() === 'warning') logs.push(m.text()); });
    page.on('pageerror', (e) => logs.push('pageerror: ' + e.message));
    await page.goto(`http://localhost:${port}/${s.query}`);
    await page.waitForTimeout(s.wait);
    await page.screenshot({ path: join(outDir, `${s.name}-${sizeName}.png`) });
    console.log(`${s.name}-${sizeName}`, logs.length ? logs.slice(0, 3) : 'ok');
    await page.close();
  }
}
await browser.close();
server.kill();
