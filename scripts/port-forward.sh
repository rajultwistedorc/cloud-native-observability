#!/usr/bin/env bash
set -euo pipefail

NS="${NAMESPACE:-observability}"

echo "==> Port-forwarding observability services (Ctrl+C to stop)"
echo "    Grafana:    http://localhost:3000"
echo "    Prometheus: http://localhost:9090"
echo "    Loki:       http://localhost:3100"
echo "    Tempo:      http://localhost:3200"
echo "    OTel:       localhost:4317 (grpc), localhost:4318 (http)"

kubectl -n "${NS}" port-forward svc/grafana 3000:3000 &
kubectl -n "${NS}" port-forward svc/prometheus 9090:9090 &
kubectl -n "${NS}" port-forward svc/loki 3100:3100 &
kubectl -n "${NS}" port-forward svc/tempo 3200:3200 &
kubectl -n "${NS}" port-forward svc/otel-collector 4317:4317 4318:4318 &

wait
