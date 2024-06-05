// usage:
// pnpm dlx tsx ./scripts/puppeteer.ts
// npx tsx ./scripts/puppeteer.ts

import { compareUrls, createReport } from "pixelteer";
import getPaths from "./puppeteer/getPaths";
import { dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const port = 9001;
const base = `https://doc.beeminder.com`;
const compare = `http://localhost:${port}`;
const outDir = `${__dirname}/../shots/`;

export async function run(argv: string[] = []) {
  await compareUrls({
    baseUrl1: base,
    baseUrl2: compare,
    outDir,
    force: argv.includes("--force"),
    paths: getPaths(),
    onSuccess: (result) => {
      console.log(result);
    },
    onError: (error) => {
      console.error(error);
    },
  });

  createReport({
    outDir,
    baseUrl1: base,
    baseUrl2: compare,
    shotsDir: outDir,
  });
}

run(process.argv);
