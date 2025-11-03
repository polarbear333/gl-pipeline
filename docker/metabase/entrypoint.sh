#!/bin/bash
set -e

DUCKDB_FILE="/data/dbt_project.duckdb"
R2_BUCKET="${CLOUDFLARE_R2_BUCKET:-fms-bucket}"
R2_URL="${AWS_ENDPOINT_URL_S3}/${R2_BUCKET}/dbt_project.duckdb"

echo "🚀 Metabase Startup"

# Check if DuckDB file exists
if [ ! -f "$DUCKDB_FILE" ]; then
    echo "📥 Downloading DuckDB from R2..."
    echo "Source: ${R2_URL}"
    
    # Download from R2 using curl with AWS authentication
    if curl -f -o "$DUCKDB_FILE" \
        --aws-sigv4 "aws:amz:auto:s3" \
        --user "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" \
        "${R2_URL}"; then
        echo "✅ Downloaded $(du -h "$DUCKDB_FILE" | cut -f1)"
    else
        echo "❌ Failed to download from R2"
        exit 1
    fi
else
    echo "✅ DuckDB exists: $(du -h "$DUCKDB_FILE" | cut -f1)"
fi

# Start Metabase
echo "🎯 Starting Metabase..."
exec java -jar /home/metabase/metabase.jar
