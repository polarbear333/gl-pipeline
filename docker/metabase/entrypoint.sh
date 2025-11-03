#!/bin/bash
set -e

DUCKDB_FILE="/data/dbt_project.duckdb"
R2_PUBLIC_URL="${R2_PUBLIC_URL:-}"

echo "🚀 Metabase Startup"

# Check if DuckDB file exists
if [ ! -f "$DUCKDB_FILE" ]; then
    if [ -n "$R2_PUBLIC_URL" ]; then
        echo "📥 Downloading DuckDB from R2 public URL..."
        echo "Source: ${R2_PUBLIC_URL}"
        
        if curl -f -L -o "$DUCKDB_FILE" "${R2_PUBLIC_URL}"; then
            echo "✅ Downloaded $(du -h "$DUCKDB_FILE" | cut -f1)"
        else
            echo "❌ Failed to download from R2"
            echo "⚠️  Starting Metabase without DuckDB file"
        fi
    else
        echo "⚠️  No R2_PUBLIC_URL set, starting without DuckDB file"
        echo "💡 You can manually upload the DuckDB file to /data/dbt_project.duckdb"
    fi
else
    echo "✅ DuckDB exists: $(du -h "$DUCKDB_FILE" | cut -f1)"
fi

# Start Metabase
echo "🎯 Starting Metabase..."
exec java -jar /home/metabase/metabase.jar
