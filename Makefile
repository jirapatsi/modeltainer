PYTHON := $(shell command -v python3 2>/dev/null || command -v python)

.PHONY: up down logs print-models

print-models:
	@$(PYTHON) scripts/print_models.py

up: print-models
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f
