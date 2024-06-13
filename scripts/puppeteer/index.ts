// usage:
// pnpm dlx tsx ./scripts/puppeteer.ts
// npx tsx ./scripts/puppeteer.ts

import { compareUrls, createReport } from "pixelteer";
import getPaths from "./getPaths";
import { dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const port = 9001;
const base = `https://doc.beeminder.com`;
const compare = `http://localhost:${port}`;
const outDir = `${__dirname}/../shots/`;

export async function run(argv: string[] = []) {
  const paths = getPaths();

  console.log(`Checking ${paths.length} paths`);

  await compareUrls({
    baseUrl1: base,
    baseUrl2: compare,
    outDir,
    force: argv.includes("--force"),
    paths,
    onSuccess: (result) => {
      console.log(result);
    },
    onError: (error) => {
      console.error(error);
    },
  });

  console.log("Creating report");

  createReport({
    outDir,
    baseUrl1: base,
    baseUrl2: compare,
    shotsDir: outDir,
  });

  console.log("Done");
}

run(process.argv);
