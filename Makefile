PYTHON := $(shell if [ -x .venv/bin/python ]; then echo .venv/bin/python; elif [ -x "$$HOME/ejscreen-venv/bin/python" ]; then echo "$$HOME/ejscreen-venv/bin/python"; else echo python3.11; fi)
COMPOSE := docker compose --env-file .env

.PHONY: db-up load build build-tier3 validate all venv schemas

venv:
	python3.11 -m venv .venv
	$(PYTHON) -m pip install -r requirements.txt

db-up:
	$(COMPOSE) up -d
	i=0; \
	until $(COMPOSE) exec -T db pg_isready -U "$$(grep '^POSTGRES_USER=' .env | cut -d= -f2)" -d "$$(grep '^POSTGRES_DB=' .env | cut -d= -f2)"; do \
	  i=$$((i+1)); \
	  if [ $$i -gt 60 ]; then echo "Postgres did not become ready"; exit 1; fi; \
	  sleep 2; \
	done

schemas: db-up
	$(PYTHON) loaders/run_sql.py sql/001_schemas.sql sql/002_raw_tables.sql

load: schemas
	$(PYTHON) loaders/download.py
	$(PYTHON) loaders/load_raw.py
	$(PYTHON) loaders/download_acs.py
	$(PYTHON) loaders/load_acs.py
	$(PYTHON) loaders/download_block_weight.py
	$(PYTHON) loaders/load_block_weight.py

build:
	$(PYTHON) loaders/run_sql.py \
	  sql/010_staging.sql \
	  sql/020_demographics.sql \
	  sql/030_percentiles_indexes.sql \
	  sql/040_scores_comments.sql \
	  sql/080_assertions.sql \
	  sql/090_acs_indicators.sql \
	  sql/091_acs_indexes.sql \
	  sql/092_acs_assertions.sql

# Tier 3 SQL expects facility and HPMS tables already loaded into raw/staging.
# Those extracts are not committed. See docs/data_sources.md and docs/publish-disclaimer.md.
build-tier3:
	$(PYTHON) loaders/run_sql.py \
	  sql/100_tier3_lead.sql \
	  sql/101_tier3_blocks.sql \
	  sql/102_tier3_proximity.sql \
	  sql/103_tier3_traffic.sql

validate:
	$(PYTHON) loaders/validate.py

all: load build validate
