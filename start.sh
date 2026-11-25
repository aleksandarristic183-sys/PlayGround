#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/dist"
PORT="${PORT:-3000}"
OPENCODE_WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"

run_timed() {
  /usr/bin/time -p "$@"
}

run_timed bash -c 'cd "$1"' _ "$PROJECT_DIR"
cd "$PROJECT_DIR"
if [[ -f package.json ]]; then
  if [[ -f package-lock.json ]]; then
    run_timed npm ci
  elif [[ -f pnpm-lock.yaml ]]; then
    run_timed pnpm install --frozen-lockfile
  elif [[ -f yarn.lock ]]; then
    run_timed yarn install --frozen-lockfile
  else
    run_timed npm install
  fi
  if node -e "process.exit(require('./package.json').scripts?.build ? 0 : 1)"; then
    run_timed npm run build
  fi
fi

run_timed rm -rf "$BUILD_DIR"
run_timed mkdir -p "$BUILD_DIR" "$OPENCODE_WEB_DIR"
run_timed cp -a "$PROJECT_DIR/public/." "$BUILD_DIR/"
run_timed python3 -c 'import json,os,sys; json.dump({"project":os.path.realpath(sys.argv[1]),"directory":os.path.realpath(sys.argv[2])},open(sys.argv[3],"w"),separators=(",",":")); open(sys.argv[3],"a").write("\n")' "$PROJECT_DIR" "$BUILD_DIR" "$OPENCODE_WEB_DIR/deployment-output.json"

if [[ ! "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
  echo "PORT must be an integer from 1 to 65535 (got: $PORT)." >&2
  exit 1
fi
exec /usr/bin/time -p python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$BUILD_DIR"
