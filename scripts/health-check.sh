#!/usr/bin/env bash
set -euo pipefail

PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
LOKI_URL="${LOKI_URL:-http://localhost:3100}"
TEMPO_URL="${TEMPO_URL:-http://localhost:3200}"
OTEL_URL="${OTEL_URL:-http://localhost:13133}"
DEMO_URL="${DEMO_URL:-http://localhost:8080}"

check() {
  local name="$1"
  local url="$2"
  if curl -fsS "${url}" >/dev/null 2>&1; then
    echo "  [OK]   ${name}"
  else
    echo "  [FAIL] ${name} (${url})"
    return 1
  fi
}

echo "==> Health check — Cloud Native Observability stack"
FAILED=0

check "Prometheus" "${PROMETHEUS_URL}/-/healthy" || FAILED=1
check "Grafana"    "${GRAFANA_URL}/api/health"     || FAILED=1
check "Loki"       "${LOKI_URL}/ready"             || FAILED=1
check "Tempo"      "${TEMPO_URL}/ready"            || FAILED=1
check "OTel Collector" "${OTEL_URL}/"              || FAILED=1
check "Demo App"   "${DEMO_URL}/health"            || FAILED=1

if [[ "${FAILED}" -eq 1 ]]; then
  echo "==> One or more services are unhealthy"
  exit 1
fi

echo "==> All services healthy"
