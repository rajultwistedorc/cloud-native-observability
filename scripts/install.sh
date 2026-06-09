#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NS="observability"
GRAFANA_USER="${GRAFANA_ADMIN_USER:-admin}"
GRAFANA_PASS="${GRAFANA_ADMIN_PASSWORD:-changeme}"

echo "==> Installing Cloud Native Observability stack to namespace: ${NS}"

kubectl apply -f "${ROOT}/kubernetes/namespace.yaml"

kubectl -n "${NS}" create secret generic grafana-admin \
  --from-literal=username="${GRAFANA_USER}" \
  --from-literal=password="${GRAFANA_PASS}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "${NS}" create configmap grafana-dashboards \
  --from-file="${ROOT}/grafana/dashboards/" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -k "${ROOT}/kubernetes/"

echo "==> Waiting for core deployments..."
kubectl -n "${NS}" rollout status deployment/prometheus --timeout=300s
kubectl -n "${NS}" rollout status deployment/loki --timeout=300s
kubectl -n "${NS}" rollout status deployment/tempo --timeout=300s
kubectl -n "${NS}" rollout status deployment/otel-collector --timeout=300s
kubectl -n "${NS}" rollout status deployment/grafana --timeout=300s

echo "==> Stack installed successfully."
echo "    Grafana:    kubectl -n ${NS} port-forward svc/grafana 3000:3000"
echo "    Prometheus: kubectl -n ${NS} port-forward svc/prometheus 9090:9090"
echo "    Credentials: ${GRAFANA_USER} / (value from GRAFANA_ADMIN_PASSWORD)"
