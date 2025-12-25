CREATE DATABASE IF NOT EXISTS observability;

SET allow_experimental_time_series_table = 1;
CREATE TABLE IF NOT EXISTS observability.metrics
ENGINE = TimeSeries;
