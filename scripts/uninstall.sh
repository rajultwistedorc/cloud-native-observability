#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NS="observability"

echo "==> Uninstalling Cloud Native Observability stack from namespace: ${NS}"

kubectl delete -k "${ROOT}/kubernetes/" --ignore-not-found
kubectl -n "${NS}" delete secret grafana-admin --ignore-not-found
kubectl -n "${NS}" delete configmap grafana-dashboards --ignore-not-found
kubectl delete namespace "${NS}" --ignore-not-found

echo "==> Uninstall complete."
