import { execSync } from "child_process";

export default function getPaths(): string[] {
  const urls = execSync(`${__dirname}/../pad-urls.sh`).toString();
  return urls
    .split("\n")
    .filter(Boolean)
    .map((url) => {
      return new URL(`https://${url}`).pathname;
    });
}
