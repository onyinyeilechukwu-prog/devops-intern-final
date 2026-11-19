#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:8080}"

code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$URL" || true)

if [ "$code" = "200" ]; then
  echo "OK: $URL returned 200"
  exit 0
fi

echo "FAIL: $URL returned '${code:-no response}', expected 200" >&2
exit 1
