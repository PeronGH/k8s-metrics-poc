#!/bin/bash
set -euo pipefail

echo "Waiting for ClickHouse..."
until clickhouse-client --host clickhouse --query "SELECT 1" >/dev/null 2>&1; do
  sleep 2
done

echo "Initializing database and tables..."
clickhouse-client --host clickhouse --multiquery < /scripts/init.sql

echo "Done."
