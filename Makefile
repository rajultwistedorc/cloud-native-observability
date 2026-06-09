COMPOSE := docker compose
ENV_FILE := .env
NS := observability

.PHONY: help up down logs ps restart validate health traffic install uninstall port-forward k8s-apply k8s-delete build-demo

help:
	@echo "Cloud Native Observability — available targets:"
	@echo "  make up            Start local stack (docker compose)"
	@echo "  make down          Stop local stack"
	@echo "  make validate      Validate all configs"
	@echo "  make health        Health-check running stack"
	@echo "  make traffic       Generate demo traffic"
	@echo "  make install       Deploy to Kubernetes"
	@echo "  make uninstall     Remove from Kubernetes"
	@echo "  make port-forward  Port-forward K8s services"
	@echo "  make build-demo    Build demo app image"

up:
	@test -f $(ENV_FILE) || cp .env.example $(ENV_FILE)
	$(COMPOSE) --env-file $(ENV_FILE) up -d --build

down:
	$(COMPOSE) --env-file $(ENV_FILE) down

logs:
	$(COMPOSE) --env-file $(ENV_FILE) logs -f --tail=100

ps:
	$(COMPOSE) --env-file $(ENV_FILE) ps

restart:
	$(COMPOSE) --env-file $(ENV_FILE) restart

validate:
	bash scripts/validate-config.sh

health:
	bash scripts/health-check.sh

traffic:
	bash scripts/generate-traffic.sh

install:
	@test -n "$(GRAFANA_ADMIN_PASSWORD)" || (echo "Set GRAFANA_ADMIN_PASSWORD" && exit 1)
	bash scripts/install.sh

uninstall:
	bash scripts/uninstall.sh

port-forward:
	bash scripts/port-forward.sh

k8s-apply:
	kubectl apply -k kubernetes/

k8s-delete:
	kubectl delete -k kubernetes/ --ignore-not-found

build-demo:
	docker build -t cloud-native-observability-demo-app:latest demo-app/

reload-prometheus:
	curl -fsS -X POST http://localhost:9090/-/reload

pull:
	$(COMPOSE) pull
