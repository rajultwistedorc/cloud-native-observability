# Cloud Native Observability

Production-ready **LGTM** stack (Loki, Grafana, Tempo, Mimir/Prometheus) with **OpenTelemetry** collector, pre-built dashboards, alerting, Kubernetes manifests, and CI.

Unified observability for metrics, logs, and traces with correlated Grafana views.

## Architecture

```text
Applications (OTLP)
        │
        ▼
┌───────────────────┐
│ OTel Collector    │
│  traces → Tempo   │
│  metrics → Prom   │
│  logs → Loki      │
└───────────────────┘
        │
   ┌────┴────┬──────────┐
   ▼         ▼          ▼
Prometheus  Loki     Tempo
   │         │          │
   └────┬────┴──────────┘
        ▼
    Grafana
 (linked datasources)
```

| Component | Role |
|-----------|------|
| **OpenTelemetry Collector** | OTLP ingestion, batching, k8s metadata enrichment |
| **Prometheus** | Metrics storage, alerting, recording rules |
| **Loki** | Log aggregation with label-based indexing |
| **Tempo** | Distributed tracing, span metrics, service graphs |
| **Grafana** | Dashboards with trace↔log↔metric correlation |
| **Alertmanager** | Alert routing and inhibition |
| **Promtail** | Kubernetes pod log shipping |

## Quick Start (Docker Compose)

```bash
cp .env.example .env
# Edit GRAFANA_ADMIN_PASSWORD

make up
make health
make traffic
```

| Service | URL |
|---------|-----|
| Grafana | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| Loki | http://localhost:3100 |
| Tempo | http://localhost:3200 |
| Demo App | http://localhost:8080 |
| OTLP (HTTP) | http://localhost:4318 |
| OTLP (gRPC) | localhost:4317 |

Default Grafana credentials: `admin` / value from `.env`.

## Kubernetes Deployment

```bash
export GRAFANA_ADMIN_PASSWORD='your-secure-password'
make install
make port-forward
```

Manifests include:
- Namespace, RBAC, PVCs (50Gi Prometheus, 30Gi Loki/Tempo, 5Gi Grafana)
- HA OTel Collector (2 replicas, pod anti-affinity)
- Promtail DaemonSet for pod logs
- Ingress with TLS (update hostnames in `kubernetes/ingress.yaml`)
- Resource requests/limits and health probes

```bash
make uninstall   # remove stack
```

## Instrument Your Application

Set these environment variables (see `opentelemetry/instrumentation/otel-sdk-config.yaml`):

```bash
OTEL_SERVICE_NAME=my-service
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
OTEL_TRACES_EXPORTER=otlp
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=production,service.version=1.0.0
```

Supported SDKs: Python, Go, Java, Node.js, .NET — all export OTLP to the collector.

## Dashboards

Pre-provisioned in Grafana under **Cloud Native Observability**:

| Dashboard | UID | Purpose |
|-----------|-----|---------|
| Observability Overview | `obs-overview` | Stack health, OTel pipeline |
| Golden Signals (RED) | `golden-signals` | Rate, errors, duration |
| Loki Logs Explorer | `loki-logs` | Log search with trace links |
| Tempo Distributed Tracing | `tempo-tracing` | Trace search, service map |

Datasources are cross-linked: click a trace ID in logs to jump to Tempo; exemplars in Prometheus link to traces.

## Alerting

Prometheus rules in `prometheus/alert_rules.yml`:

| Alert | Severity | Condition |
|-------|----------|-----------|
| PrometheusTargetDown | critical | `up == 0` for 5m |
| OtelCollectorDown | critical | Collector unreachable |
| HighErrorRate | warning | >5% 5xx responses |
| HighP99Latency | warning | P99 > 2s for 10m |
| LokiIngesterDown | critical | Loki unreachable |
| TempoIngesterDown | critical | Tempo unreachable |

Configure Slack webhooks via `ALERTMANAGER_SLACK_WEBHOOK_URL` in `.env`.

## Project Layout

```text
cloud-native-observability/
├── opentelemetry/          # Collector configs (compose + k8s)
├── prometheus/             # Scrape, alert, recording rules
├── loki/                   # Loki + Promtail configs
├── tempo/                  # Tempo tracing backend
├── grafana/                # Datasources, dashboards
├── kubernetes/             # Production K8s manifests (kustomize)
├── demo-app/               # Instrumented FastAPI sample
├── scripts/                # install, validate, health-check
├── .github/workflows/      # CI pipeline
├── docker-compose.yml
├── Makefile
└── README.md
```

## CI Pipeline

GitHub Actions (`.github/workflows/ci.yml`):

1. **validate** — YAML lint, kubeconform, kustomize dry-run, dashboard JSON
2. **build-demo-app** — Docker build + health smoke test
3. **integration** — Full stack up, health check, traffic generation

## Production Checklist

- [ ] Set strong `GRAFANA_ADMIN_PASSWORD`
- [ ] Configure Alertmanager Slack/PagerDuty receivers
- [ ] Update Ingress hostnames and TLS certificates
- [ ] Adjust PVC sizes for your retention needs
- [ ] Enable object storage for Loki/Tempo at scale (S3/GCS)
- [ ] Replace demo-app image with your instrumented services
- [ ] Review resource limits for your cluster capacity

## Makefile Reference

```bash
make help          # Show all targets
make up            # Start local stack
make validate      # Validate configs
make health        # Check service health
make traffic       # Generate demo requests
make install       # Deploy to Kubernetes
make port-forward  # Access K8s services locally
```

## License

MIT

## Live Screenshots

### Grafana with Loki and Tempo
![Grafana Observability](screenshots/grafana-observability.png)
