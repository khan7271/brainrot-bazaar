// Brainrot Bazaar — my entry for make.fun's roblox-brainrot-01 bounty.
// The game lives in src/ as a Rojo project: Luau scripts under src/server,
// src/client and src/shared build a 3D Roblox place (plaza, conveyor belt,
// eight player bases, thieves and a sauce tsunami) entirely in code, and
// `rojo build default.project.json --output game.rbxl` turns them into the
// binary place file. This program is the hand-in: it copies game.rbxl,
// src/, screenshots/ and PLAY.json from beside this file into /output and
// writes /output/dossier.json, the summary the judge reads, using the
// vendored make.fun library (vendor/makefun-roblox.ts, unchanged).
//
// Every name under /output must start with a letter, a digit or _ and hold
// only letters, digits, . _ and -: the grader fails an entry whose output
// holds any other, so a file such as .gitkeep or .DS_Store copied in fails
// it. So src/ and screenshots/ are copied without any name that starts
// with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// Validate the place link the judge will open: PLAY.json must parse and
// carry a real url, place_id and universe_id. A placeholder only warns -
// the hand-in still builds - because the IDs are filled in after the
// experience is published in Studio.
let playSummary = 'PLAY.json: missing';
try {
  const play = JSON.parse(readFileSync(join(here, 'PLAY.json'), 'utf8')) as Record<string, unknown>;
  const missing = ['url', 'place_id', 'universe_id'].filter((key) => play[key] === undefined || play[key] === 0 || play[key] === '');
  if (missing.length > 0) {
    console.warn(`PLAY.json is incomplete (missing: ${missing.join(', ')}). Fill it in after publishing the experience.`);
    playSummary = `PLAY.json: incomplete (${missing.join(', ')})`;
  } else {
    playSummary = `PLAY.json: ${String(play.url)}`;
  }
} catch (error) {
  console.warn(`PLAY.json could not be parsed: ${error instanceof Error ? error.message : String(error)}`);
}

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);

// One-line build summary: how many files were copied and how big the
// dossier is, so a failed or half-empty hand-in is obvious at a glance.
const countFiles = (dir: string): number => {
  let total = 0;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const child = join(dir, entry.name);
    total += entry.isDirectory() ? countFiles(child) : 1;
  }
  return total;
};
const copiedFiles = countFiles(join(out, 'src')) + countFiles(join(out, 'screenshots')) + 2;
const dossierBytes = statSync(join(out, 'dossier.json')).size;
console.log(`Brainrot Bazaar hand-in ready: ${copiedFiles} files copied, dossier ${dossierBytes} bytes, ${playSummary}.`);
