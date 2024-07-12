"use strict";

const request = require("supertest");
const express = require("express");
const { expressPreSession } = require("./expressPreSession");
const expost = require("expost");

jest.mock("ep_etherpad-lite/node/db/API", () => ({
  getText: jest.fn(() => "text"),
}));
jest.mock("ep_etherpad-lite/node/eejs", () => ({
  require: jest.fn(() => "html"),
}));
jest.mock("expost", () => ({
  parseMarkdown: jest.fn(() => "body"),
  parseTitle: jest.fn(() => "title"),
}));

describe("expressPreSession", () => {
  const originalEnv = process.env;
  let app;

  beforeEach(() => {
    process.env = { ...originalEnv, ETHERPAD_SECRET_DOMAIN: "127.0.0.1" };
    app = express();
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it("does not redirect if public=true", async () => {
    expressPreSession(undefined, {
      app,
    });

    const res = await request(app).get("/p/foo?public=true");

    expect(res.status).toBe(200);
  });

  it("uses expost if public=true", async () => {
    expressPreSession(undefined, {
      app,
    });

    await request(app).get("/p/foo?public=true");

    expect(expost.parseMarkdown).toHaveBeenCalled();
  });

  it("does not redirect /api/404", async () => {
    expressPreSession(undefined, {
      app,
    });

    const res = await request(app).get("/api/404");

    expect(res.status).toBe(404);
  });

  it("does not redirect /p/foo/timeslider if not public", async () => {
    expressPreSession(undefined, {
      app,
    });

    app.get("/p/:pad/timeslider", (req, res) => {
      res.status(200).send("ok");
    });

    const res = await request(app).get("/p/foo/timeslider");

    expect(res.status).toBe(200);
  });

  it("does not redirect timeslider with time tag", async () => {
    expressPreSession(undefined, {
      app,
    });

    app.get("/p/:pad/timeslider", (req, res) => {
      res.status(200).send("ok");
    });

    const res = await request(app).get("/p/foo/timeslider#123");

    expect(res.status).toBe(200);
  });
});
