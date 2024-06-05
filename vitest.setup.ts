import { beforeEach, vi } from "vitest";
import getPaths from "./scripts/puppeteer/getPaths";

vi.mock("./scripts/puppeteer/getPaths");
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
vi.mock("pixelteer");
vi.mock("pngjs");
vi.mock("sharp");

beforeEach(() => {
  global.fetch = vi.fn(() =>
    Promise.resolve({ text: vi.fn(async () => "") } as any)
  );

  vi.mocked(fetch).mockReturnValue(
    Promise.resolve({ text: vi.fn(async () => "") } as any)
  );

  vi.mocked(getPaths).mockResolvedValue([]);

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
