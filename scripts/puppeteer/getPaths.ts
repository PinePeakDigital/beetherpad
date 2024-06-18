import { execSync } from "child_process";

export default function getPaths(): string[] {
  const urls = execSync(`${__dirname}/../pad-slugs.sh`).toString();
  return urls
    .split("\n")
    .filter(Boolean)
    .map((slug) => `/${slug}`);
}
