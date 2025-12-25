CREATE DATABASE IF NOT EXISTS observability;

CREATE TABLE IF NOT EXISTS observability.metrics
(
    timestamp DateTime,
    metric_name String,
    value Float64,
    tags Map(String, String)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMMDD(timestamp)
ORDER BY (metric_name, tags['namespace'], timestamp)
TTL timestamp + INTERVAL 90 DAY;
