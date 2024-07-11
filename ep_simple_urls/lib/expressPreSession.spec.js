"use strict";

const request = require("supertest");
const express = require("express");
const { expressPreSession } = require("./expressPreSession");
const expost = require("expost");

const app = express();

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

  beforeEach(() => {
    process.env = { ...originalEnv, ETHERPAD_SECRET_DOMAIN: "127.0.0.1" };
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
});
