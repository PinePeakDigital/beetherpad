import { beforeEach, vi } from "vitest";
import getSitemap from "./src/lib/getSitemap";
import readScreenshot from "./src/lib/readScreenshot";

vi.mock("./src/lib/fetchPost");
vi.mock("./src/lib/readSources");
vi.mock("./src/lib/test/createReport");
vi.mock("./src/lib/test/saveScreenshot");
vi.mock("./src/lib/test/getSitemap");
vi.mock("./src/lib/test/readScreenshot");
vi.mock("./src/lib/test/resizeImage");
vi.mock("node-fetch-cache");
vi.mock("puppeteer", () => ({
  default: {
    launch: vi.fn(async () => ({
      newPage: vi.fn(async () => ({
        setViewport: vi.fn(),
        goto: vi.fn(),
        screenshot: vi.fn(),
        close: vi.fn(),
      })),
      close: vi.fn(),
    })),
  },
}));
vi.mock("fs");
vi.mock("astro", () => ({
  preview: vi.fn(async () => ({
    stop: vi.fn(),
  })),
}));
vi.mock("pixelmatch");
vi.mock("pngjs");
vi.mock("sharp");

beforeEach(() => {
  global.fetch = vi.fn(() =>
    Promise.resolve({ text: vi.fn(async () => "") } as any)
  );

  vi.mocked(fetch).mockReturnValue(
    Promise.resolve({ text: vi.fn(async () => "") } as any)
  );

  vi.mocked(getSitemap).mockResolvedValue([]);
  vi.mocked(readScreenshot).mockReturnValue({
    metadata: () => ({
      width: 100,
      height: 100,
    }),
  } as any);

  vi.stubGlobal("console", {
    ...console,
    info: vi.fn(),
    time: vi.fn(),
    timeEnd: vi.fn(),
  });

  vi.stubGlobal("process", {
    ...process,
    env: { ...process.env, ETHERPAD_DOMAIN: "the_etherpad_domain" },
  });
});
