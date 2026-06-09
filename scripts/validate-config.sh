#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

check_yaml() {
  local file="$1"
  echo "  validating ${file}"
  if ! python3 -c "import yaml; yaml.safe_load_all(open('${file}'))" 2>/dev/null; then
    if ! python -c "import yaml; yaml.safe_load_all(open('${file}'))" 2>/dev/null; then
      echo "  ERROR: invalid YAML in ${file}"
      FAILED=1
    fi
  fi
}

echo "==> Validating YAML configuration files"

for f in \
  "${ROOT}/opentelemetry/collector-config.yaml" \
  "${ROOT}/opentelemetry/collector-k8s.yaml" \
  "${ROOT}/loki/loki-config.yaml" \
  "${ROOT}/loki/promtail-config.yaml" \
  "${ROOT}/tempo/tempo-config.yaml" \
  "${ROOT}/prometheus/prometheus.yml" \
  "${ROOT}/prometheus/alert_rules.yml" \
  "${ROOT}/prometheus/recording_rules.yml" \
  "${ROOT}/prometheus/alertmanager.yml" \
  "${ROOT}/grafana/provisioning/datasources/datasources.yml" \
  "${ROOT}/grafana/provisioning/dashboards/dashboards.yml"; do
  check_yaml "$f"
done

echo "==> Validating docker-compose"
docker compose -f "${ROOT}/docker-compose.yml" config >/dev/null

echo "==> Validating Kubernetes manifests (client dry-run)"
kubectl apply --dry-run=client -k "${ROOT}/kubernetes/" >/dev/null

if [[ "${FAILED}" -eq 1 ]]; then
  echo "==> Validation FAILED"
  exit 1
fi

echo "==> All configurations valid"
