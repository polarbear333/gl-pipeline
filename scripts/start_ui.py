import duckdb

print("Starting DuckDB UI server")
con = duckdb.connect('dbt_project/dbt_project.duckdb')
con.execute('CALL start_ui();')
print("Server started! Press Ctrl+C to stop.")

try:
    while True:
        pass
except KeyboardInterrupt:
    print("Shutting down server")
    con.close()