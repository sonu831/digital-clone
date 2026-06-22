# ══════════════════════════════════════════════════════════════════════════════
#  Digital Clone — developer convenience targets.  Run `make help` for the list.
# ══════════════════════════════════════════════════════════════════════════════
SHELL := /bin/bash
COMPOSE := docker compose

.DEFAULT_GOAL := help

.PHONY: help bootstrap up down restart logs ps health pull-models \
        export-workflows import-workflows backup migrate clean nuke

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-18s\033[0m %s\n",$$1,$$2}'

bootstrap: ## First-time setup: create .env, generate secrets, start, pull models
	@./scripts/bootstrap.sh

up: ## Start the stack in the background
	$(COMPOSE) up -d

down: ## Stop the stack (keeps volumes/data)
	$(COMPOSE) down

restart: ## Restart all services
	$(COMPOSE) restart

logs: ## Tail logs (use: make logs s=n8n to filter one service)
	$(COMPOSE) logs -f $(s)

ps: ## Show container status
	$(COMPOSE) ps

health: ## Probe all services + list installed models
	@./scripts/healthcheck.sh

pull-models: ## Pull the models listed in OLLAMA_MODELS
	@./scripts/pull-models.sh

export-workflows: ## Export n8n workflows from the DB into n8n/workflows/
	$(COMPOSE) exec n8n n8n export:workflow --all --separate --pretty --output=/workflows

import-workflows: ## Import the JSON in n8n/workflows/ into n8n
	$(COMPOSE) exec n8n n8n import:workflow --separate --input=/workflows

backup: ## Dump Postgres (n8n state + clone schema) to ./backups/
	@./scripts/backup.sh

migrate: ## Apply additive SQL in db/migrations/ (in lexical order)
	@for f in $$(ls db/migrations/*.sql 2>/dev/null | sort); do \
	  echo "→ applying $$f"; \
	  $(COMPOSE) exec -T postgres psql -U $$(grep -E '^POSTGRES_USER=' .env|cut -d= -f2-) \
	    -d $$(grep -E '^POSTGRES_DB=' .env|cut -d= -f2-) < $$f; \
	done

clean: ## Stop and remove containers + networks (KEEPS data volumes)
	$(COMPOSE) down --remove-orphans

nuke: ## DESTROY everything incl. data volumes (irreversible — back up first!)
	$(COMPOSE) down -v --remove-orphans
