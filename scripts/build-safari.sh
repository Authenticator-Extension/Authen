#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/authenticator"

case ":${NODE_OPTIONS:-}:" in
    *--openssl-legacy-provider*) ;;
    *) export NODE_OPTIONS="${NODE_OPTIONS:-} --openssl-legacy-provider" ;;
esac

if [[ ! -d node_modules ]]; then
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true npm ci
fi

npm run safari
