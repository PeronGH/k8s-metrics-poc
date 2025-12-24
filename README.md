# k8s-metrics-poc

Vector + ClickHouse proof-of-concept for Kubernetes metrics and logs collection.

## What this does

- **Vector (DaemonSet)** collects logs and metrics from all pods
- **ClickHouse** stores both logs (MergeTree table) and metrics (TimeSeries table)
- Logs sent via ClickHouse HTTP sink
- Metrics sent via Prometheus remote_write

## Deploy

```bash
kubectl apply -k k8s/
```

## Access ClickHouse

Open the web UI in your browser:

**<http://localhost:30123/play>**

## Get Table UUID

Find your TimeSeries table UUID:

```sql
SHOW TABLES FROM observability LIKE '.inner_id%';
```

Look for `.inner_id.tags.<UUID>` and `.inner_id.data.<UUID>`.

## Remove

```bash
kubectl delete -k k8s/
```

> **Note:** You may see `Error from server (NotFound): error when deleting "k8s/": secrets "vector-sa-token" not found`. This is expected and harmless - the Secret is automatically cleaned up when the ServiceAccount is deleted.

## Billing Query

Single query to get all billing metrics per namespace for a time period:

```sql
WITH latest AS (
    SELECT
        tags['namespace'] as namespace,
        metric_name,
        argMax(value, timestamp) as latest_value
    FROM observability.`.inner_id.data.<YOUR-UUID-HERE>` as data
    JOIN observability.`.inner_id.tags.<YOUR-UUID-HERE>` as tags USING(id)
    WHERE tags['namespace'] != ''
      AND timestamp >= now() - INTERVAL 1 HOUR
    GROUP BY namespace, metric_name, id
)
SELECT
    namespace,
    round(sumIf(latest_value, metric_name = 'container_cpu_usage_seconds_total'), 2) as cpu_seconds,
    round(avgIf(latest_value / 1024 / 1024, metric_name = 'container_memory_working_set_bytes'), 2) as memory_mb,
    round(sumIf(latest_value / 1024 / 1024 / 1024, metric_name IN ('container_network_receive_bytes_total', 'container_network_transmit_bytes_total')), 4) as network_gb,
    round(if(isNaN(avgIf(latest_value / 1024 / 1024 / 1024, metric_name = 'container_fs_usage_bytes')), 0, avgIf(latest_value / 1024 / 1024 / 1024, metric_name = 'container_fs_usage_bytes')), 4) as disk_gb
FROM latest
GROUP BY namespace
ORDER BY memory_mb DESC;
```

Replace `<YOUR-UUID-HERE>` with the actual UUID from `SHOW TABLES FROM observability LIKE '.inner_id%';`

## Optional: Grafana

To visualize with Grafana, you can add the ClickHouse data source plugin.

Configure Grafana with:

- **Server**: localhost:30900
- **Protocol**: Native
- **Database**: observability
