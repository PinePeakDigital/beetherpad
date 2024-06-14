#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR/puppeteer"
pnpm install
pnpm run puppeteer -- "$@" | tee "$SCRIPT_DIR/puppeteer.log"