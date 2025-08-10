.PHONY: up down logs print-models

print-models:
	@python scripts/print_models.py

up: print-models
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f
