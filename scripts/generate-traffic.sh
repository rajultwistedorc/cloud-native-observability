#!/usr/bin/env bash
set -euo pipefail

DEMO_URL="${DEMO_URL:-http://localhost:8080}"
REQUESTS="${REQUESTS:-100}"
FAIL_RATE="${FAIL_RATE:-0.15}"

echo "==> Generating ${REQUESTS} requests to ${DEMO_URL}"

for i in $(seq 1 "${REQUESTS}"); do
  endpoint=$([[ $((i % 3)) -eq 0 ]] && echo "/api/chain" || echo "/api/work?fail_rate=${FAIL_RATE}")
  curl -fsS "${DEMO_URL}${endpoint}" >/dev/null || true
  sleep 0.1
done

echo "==> Traffic generation complete. Check Grafana dashboards for metrics, logs, and traces."
