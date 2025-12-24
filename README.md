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

## Query Examples

### View recent logs

```sql
SELECT ts, namespace, pod, container, message
FROM observability.logs
ORDER BY ts DESC
LIMIT 20
```

### View logs from specific namespace

```sql
SELECT ts, pod, container, message
FROM observability.logs
WHERE namespace = 'kube-system'
ORDER BY ts DESC
LIMIT 50
```

### Count logs by namespace

```sql
SELECT namespace, count() as log_count
FROM observability.logs
WHERE ts > now() - INTERVAL 5 MINUTE
GROUP BY namespace
ORDER BY log_count DESC
```

### Metrics Queries

> **Note**: The `metrics` table uses ClickHouse's experimental TimeSeries engine, which doesn't support direct SELECT queries yet. Query the inner tables instead.

**First, find the table UUID:**

```sql
SHOW TABLES FROM observability LIKE '.inner_id%';
```

Look for tables like `.inner_id.tags.<UUID>` and `.inner_id.data.<UUID>`. Use this UUID in queries below.

### View available metrics

```sql
SELECT metric_name, count() as metric_count, min(min_time) as first_seen, max(max_time) as last_seen
FROM observability.`.inner_id.tags.fd4f2a4e-59ac-43cf-bdb9-db531dbaa3d9`
GROUP BY metric_name
ORDER BY metric_count DESC
LIMIT 20;
```

### View specific metric with tags

```sql
SELECT metric_name, tags, min_time, max_time
FROM observability.`.inner_id.tags.fd4f2a4e-59ac-43cf-bdb9-db531dbaa3d9`
WHERE metric_name = 'container_memory_working_set_bytes'
  AND has(mapKeys(tags), 'namespace')
  AND tags['namespace'] != ''
LIMIT 20;
```

### Count total metric samples

```sql
SELECT count() as total_samples
FROM observability.`.inner_id.data.fd4f2a4e-59ac-43cf-bdb9-db531dbaa3d9`;
```

### View metrics by namespace (from tags)

```sql
SELECT
    tags['namespace'] as namespace,
    metric_name,
    count() as count
FROM observability.`.inner_id.tags.fd4f2a4e-59ac-43cf-bdb9-db531dbaa3d9`
WHERE tags['namespace'] != ''
GROUP BY namespace, metric_name
ORDER BY count DESC
LIMIT 20;
```

## Remove

```bash
kubectl delete -k k8s/
```

## Optional: Grafana

To visualize with Grafana, you can add the ClickHouse data source plugin:

```bash
kubectl -n metrics-poc port-forward svc/clickhouse 9000:9000
```

Then configure Grafana with:

- **Server**: localhost:9000
- **Protocol**: Native
- **Database**: observability
