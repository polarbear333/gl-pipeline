import duckdb
import os
import time
from pathlib import Path


def export_gold_to_parquet():
    db_path = 'dbt_project/dbt_project.duckdb'
    export_dir = 'data/gold'

    if not os.path.exists(db_path):
        raise FileNotFoundError(f"DuckDB file not found: {db_path}")
    os.makedirs(export_dir, exist_ok=True)

    print(f"Connecting to DuckDB at: {db_path}")
    con = duckdb.connect(db_path, read_only=True)

    try:
        tables = con.execute("SHOW TABLES").fetchall()
        total = len(tables)
        print(f"Found {total} tables to export.")

        for i, (table_name,) in enumerate(tables, 1):
            start = time.time()
            out_path = Path(export_dir) / f"{table_name}.parquet"
            print(f"[{i}/{total}] Exporting {table_name} -> {out_path}")
            con.execute(f"COPY {table_name} TO '{out_path}' (FORMAT PARQUET, CODEC 'ZSTD')")
            elapsed = time.time() - start
            print(f"  ✅ {table_name} done in {elapsed:.2f}s")

        print(f"✅ Successfully exported all {total} tables to {export_dir}")

    finally:
        con.close()


if __name__ == "__main__":
    export_gold_to_parquet()
