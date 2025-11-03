"""
Explore DuckDB database structure for dashboard creation
"""
import duckdb
import sys

DB_PATH = "c:/Users/matth/Documents/Programming/Project/financial-monitoring-system/data/metabase/dbt_project.duckdb"

def explore_database():
    conn = duckdb.connect(DB_PATH, read_only=True)
    
    print("=" * 80)
    print("SCHEMAS")
    print("=" * 80)
    schemas = conn.execute("SELECT schema_name FROM information_schema.schemata").fetchall()
    for schema in schemas:
        print(f"  - {schema[0]}")
    
    print("\n" + "=" * 80)
    print("TABLES BY SCHEMA")
    print("=" * 80)
    
    tables_query = """
        SELECT table_schema, table_name, table_type 
        FROM information_schema.tables 
        WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
        ORDER BY table_schema, table_name
    """
    tables = conn.execute(tables_query).fetchall()
    
    current_schema = None
    for schema, table, table_type in tables:
        if schema != current_schema:
            print(f"\n[{schema}]")
            current_schema = schema
        print(f"  - {table} ({table_type})")
    
    print("\n" + "=" * 80)
    print("TABLE DETAILS")
    print("=" * 80)
    
    for schema, table, _ in tables:
        if schema in ('information_schema', 'pg_catalog'):
            continue
            
        print(f"\n{schema}.{table}")
        print("-" * 80)
        
        # Get columns
        cols_query = f"""
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = '{schema}' AND table_name = '{table}'
            ORDER BY ordinal_position
        """
        columns = conn.execute(cols_query).fetchall()
        
        print("Columns:")
        for col_name, data_type, nullable in columns:
            null_str = "NULL" if nullable == "YES" else "NOT NULL"
            print(f"  - {col_name}: {data_type} ({null_str})")
        
        # Get row count
        try:
            count = conn.execute(f'SELECT COUNT(*) FROM {schema}.{table}').fetchone()[0]
            print(f"Row count: {count:,}")
        except:
            print("Row count: Unable to determine")
        
        # Sample data
        try:
            print("\nSample data (first 3 rows):")
            sample = conn.execute(f'SELECT * FROM {schema}.{table} LIMIT 3').fetchdf()
            print(sample.to_string())
        except Exception as e:
            print(f"Unable to fetch sample: {e}")
    
    conn.close()

if __name__ == "__main__":
    explore_database()
