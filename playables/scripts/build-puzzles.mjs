// Compacts the compact 5x5 puzzle library (../content/compact/puzzles-compact.json, built by
// engine/compact_pipeline.py) into the shape the game loads. The 10x10 library in content/puzzles-v2.json
// is not used here: its boards are too large for a casual phone game.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const src = resolve(here, '../../content/compact/puzzles-compact.json');
const out = resolve(here, '../src/generated/puzzles.json');

const all = JSON.parse(readFileSync(src, 'utf8'));
const MODES = new Set(['kanjiNankuroCompact']);
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
