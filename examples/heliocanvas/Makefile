COMPOSE = docker compose -f docker-compose.yml -f docker-compose.local-ai.yml

.PHONY: setup demo up down logs status verify test

setup:
	./setup.sh

demo up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f grott api ollama

status:
	curl -fsS http://localhost:$${DASHBOARD_PORT:-8080}/api/status

verify:
	./verify-live.sh

test:
	flutter analyze
	flutter test
	python3 -m py_compile backend/main.py
	docker compose config -q
