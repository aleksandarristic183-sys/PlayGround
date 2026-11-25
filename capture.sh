#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CAPTURE_URL="${CAPTURE_URL:?Set CAPTURE_URL to the exact preview URL.}"
CAPTURE_DIR="${CAPTURE_DIR:?Set CAPTURE_DIR to the evidence output directory.}"

run_timed() {
  /usr/bin/time -p "$@"
}

if [[ ! "$CAPTURE_URL" =~ ^https?:// ]]; then
  echo "CAPTURE_URL must be an absolute HTTP(S) URL." >&2
  exit 1
fi
CAPTURE_DIR="$(/usr/bin/time -p realpath -m -- "$CAPTURE_DIR")"
if [[ "$CAPTURE_DIR" == "$PROJECT_DIR" || "$CAPTURE_DIR" == "$PROJECT_DIR/"* ]]; then
  echo "CAPTURE_DIR must be outside the project source directory." >&2
  exit 1
fi
run_timed mkdir -p "$CAPTURE_DIR"

export CAPTURE_READY_SELECTOR='#app'
export CAPTURE_STRICT=1
run_timed node "${RUNTIME_DIR:?}/scripts/default-capture.mjs"
