# Financial Monitoring System

End-to-end, reproducible pipeline to ingest, validate, transform, and publish financial ledger data for analytics and audit.

## Summary

This repository contains a production-oriented data engineering pipeline that: ingests raw ledger CSVs, builds a cleaned Silver layer with dbt (DuckDB), validates data with Great Expectations (GE), produces Gold dimensional/fact marts with dbt, and exports analytics-ready Parquet artifacts. The full pipeline is orchestrated and made reproducible with DVC.

Tech stack: Python, dbt (DuckDB), DuckDB, Great Expectations, DVC, Parquet, and lightweight notebooks for exploration.

## Architecture & Flow

- Ingest (Python) -> Silver (dbt on DuckDB) -> Validate (Great Expectations) -> Gold (dbt) -> Export Parquet (DVC)
- DuckDB is embedded (no server) and used both by dbt and by small helper scripts to read CSV and write Parquet.
- DVC stages chain the end-to-end workflow so the pipeline can be reproduced deterministically.

## Quickstart

Minimal steps to run the pipeline locally. These assume you have Python, pip, dbt (with DuckDB adapter), DuckDB, and DVC installed.
```
# 0) Clone the repository 
git clone https://gitea.com/polarbear333/gl-pipeline
cd financial-monitoring-system

# 1) Install Python deps (use your environment/venv)
pip install -r requirements/base.txt

# 2) Ingest raw ledger CSVs into data/raw/
python -m src.data.ingest_raw_data

# 3) Prepare dbt and run the Silver staging model
dbt deps --project-dir dbt_project
dbt seed --project-dir dbt_project
dbt run --project-dir dbt_project --select stg_ledger

# 4) Validate Silver outputs with Great Expectations
python scripts/validations/run_ge_validation.py

# 5) Build Gold models and run dbt tests
dbt run --project-dir dbt_project --models gold.*
dbt test --project-dir dbt_project

# Alternatively you can run the whole reproducible pipeline using DVC:
dvc repro
```

See `dvc.yaml` for the default stages and their order.

## Continuous Integration

A GitHub Actions workflow is provided at `.github/workflows/ci.yml` that runs on push and pull requests against `main`/`master`.

What CI does:
- Installs Python dependencies and common dev tools
- Runs linting (`ruff`), type checks (`mypy`), and black format check
- Runs dbt deps/seed and builds the Silver staging model (`stg_ledger`)
- Runs Great Expectations validation for Silver
- Builds Gold models and runs dbt tests

Run CI steps locally (quick):

```powershell
# create and activate a venv
python -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install -r requirements/base.txt
pip install dbt-duckdb duckdb dvc great_expectations ruff black mypy

# lint + type + format-check
ruff .
mypy .
black --check .

# dbt + GE + tests (ensure data/raw exists or run ingestion)
dbt deps --project-dir dbt_project
dbt seed --project-dir dbt_project
dbt run --project-dir dbt_project --select stg_ledger
python scripts/validations/run_ge_validation.py
dbt run --project-dir dbt_project --models gold.*
dbt test --project-dir dbt_project
```

If you want CI to additionally run `dvc repro` (end-to-end) or export gold Parquet artifacts, add a step to the workflow to install any system deps and run `dvc repro` — be mindful of time and storage in CI.

## Key files & folders

- `src/` — Python ingestion and utility code. Notable files:
  - `src/data/ingest_raw_data.py`, `src/data/ingestion.py` — ingestion, concurrent downloads, checksums, metadata
  - `src/config/settings.py` — path and environment settings
- `dbt_project/` — dbt models, macros, seeds, and `profiles.yml` for DuckDB. Models are layered as `silver` and `gold`.
  - `dbt_project/models/silver/stg_ledger.sql` — staging logic (casts, trimming, business keys, `ledger_sk`), writes Parquet as a post-hook
  - `dbt_project/models/gold/` — dimensions, facts, marts (surrogate-key generation via `dbt_utils`)
- `great_expectations/` — GE config, expectations, and (uncommitted) data docs output location
- `scripts/validations/` — scripts that create ephemeral GE contexts and validate Parquet datasets (silver & gold)
- `dvc.yaml` & `dvc.lock` — pipeline orchestration and reproducible runspecs
- `data/` — data lake (raw/, silver/, gold/, processed/). Parquet artifacts for downstream consumers live under `data/gold/`.
- `notebooks/` & `scripts/analysis/` — profiling, exploration, and MLflow-backed profiling

## Conventions & Important Details

- Silver stage preserves business keys and row-level traceability (`row_id`, `source_path`). Use these to trace any Gold record back to source rows.
- Gold models use `dbt_utils.generate_surrogate_key([ ... ])` to derive `*_sk` fields. Facts join dims on business keys before selecting `*_sk`.
- Put business-rule tests in dbt YAML or in `tests/generic/` as SQL tests for reusable rules.
- `dbt_project.duckdb` profile uses extensions like `httpfs` and `parquet`; ensure these are enabled if exporting/importing external Parquet files.
- For large CSVs the Silver stage uses `sample_size=-1` and `union_by_name=true` to stabilize schema inference.

## Validation & Data Quality

- Great Expectations is used to validate the Silver Parquet and can be run via the supplied script which produces HTML data docs under:

  `great_expectations/uncommitted/data_docs/local_site/`

- A gold validation script pattern is included (see `scripts/validations/run_ge_validation_gold.py` in the repo notes) which should be wired into DVC as a post-export validation stage to produce `local_site_gold/` data docs.

## DVC orchestration

- The pipeline stages in `dvc.yaml` are ordered to ensure reproducibility:
  - `ingest` → `transform_to_silver` → `validate_silver_data` → `transform_to_gold`
- Use `dvc repro` to run the pipeline end-to-end. DVC tracks large artifacts and ensures reproducible outputs across environments.

## Development & Testing

- Use dbt's `seed`, `run`, and `test` commands to iterate on models. Seed files live in `dbt_project/seeds/`.
- Add or update dbt YAML tests for columns and add SQL-based generic tests under `tests/generic/` for reusable business rules.
- Notebooks under `notebooks/` and `scripts/analysis/` provide profiling and exploratory support; profiling outputs are stored under `processed/profiles/`.

## Troubleshooting

- If dbt can't find raw data: ensure `data/raw/` exists and `vars.raw_data_path` (in dbt `sources.yml`) matches the CSV pattern used by `stg_ledger.sql`.
- If GE data docs don't appear: verify `great_expectations.yml` config and the `run_ge_validation.py` script's `DATA_ASSET_NAME` path.
- For memory/CPU issues with DuckDB on large CSVs, consider splitting files or increasing available memory; DuckDB handles large files efficiently but your host matters.

## Contribution

1. Fork, create a feature branch, and open a PR.
2. Update or add dbt models under `dbt_project/models/` and accompany with tests (YAML or SQL in `tests/`).
3. If adding exported artifacts, update `dvc.yaml` and add validation scripts as needed.
4. Run `dvc repro` locally and ensure GE validations pass before merging.

## License & Attribution

```
This repository is released under the MIT License. 
Copyright (c) 2025-present polarbear333
```

---
