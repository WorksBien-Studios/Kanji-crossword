// Compacts the validated puzzle library (../content/puzzles-v2.json) into the shape the game loads.
// Only the standard-size mode is bundled for now; the 13x13 "large" mode is left out (see README).
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const src = resolve(here, '../../content/puzzles-v2.json');
const out = resolve(here, '../src/generated/puzzles.json');

const all = JSON.parse(readFileSync(src, 'utf8'));
const MODES = new Set(['kanjiNankuro']);
const puzzles = all
  .filter((p) => MODES.has(p.mode))
  .map((p) => {
    const nums = {};
    for (const [key, n] of Object.entries(p.cellNumbers)) nums[key] = n;
    return {
      id: p.id,
      d: p.difficulty,
      s: p.difficultyScore,
      r: p.rows,
      c: p.columns,
      g: p.cellLayout.map((row) => row.join('')),
      n: nums,
      k: p.solution,
      st: Object.keys(p.starterCells).map(Number),
      t: p.traySeed,
    };
  });

mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, JSON.stringify(puzzles));
console.log(`puzzles: ${puzzles.length} written to ${out}`);
