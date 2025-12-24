CREATE DATABASE IF NOT EXISTS observability;

CREATE TABLE IF NOT EXISTS observability.logs
(
  ts DateTime64(3),
  node LowCardinality(String),
  namespace LowCardinality(String),
  pod LowCardinality(String),
  container LowCardinality(String),
  message String,
  event String
)
ENGINE = MergeTree
PARTITION BY toDate(ts)
ORDER BY (namespace, pod, container, ts);

SET allow_experimental_time_series_table = 1;
CREATE TABLE IF NOT EXISTS observability.metrics
ENGINE = TimeSeries;
