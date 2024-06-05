import pixelmatch from "pixelmatch";
import { describe, it, expect, beforeEach, vi } from "vitest";
import { run } from "./puppeteer.js";
import getPaths from "./puppeteer/getPaths.js";
import fs from "fs";
import { compareUrls, createReport } from "pixelteer";

describe("puppeteer", () => {
  beforeEach(() => {
    vi.mocked(getPaths).mockReturnValue(["/"]);
  });

  it("creates report", async () => {
    await run();

    expect(createReport).toBeCalled();
  });

  it("compares paths", async () => {
    await run();

    expect(compareUrls).toBeCalledWith(
      expect.objectContaining({ paths: ["/"] })
    );
  });
});
