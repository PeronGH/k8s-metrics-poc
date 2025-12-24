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

Port-forward the ClickHouse service:

```bash
kubectl -n metrics-poc port-forward svc/clickhouse 8123:8123
```

Then open the web UI in your browser:

**<http://localhost:8123/play>**

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

### View available metrics

```sql
SELECT metric_name, count() as sample_count
FROM observability.metrics
WHERE timestamp > now() - INTERVAL 5 MINUTE
GROUP BY metric_name
ORDER BY sample_count DESC
LIMIT 20
```

### Container memory usage by namespace

```sql
SELECT
    tags['namespace'] AS namespace,
    tags['pod'] AS pod,
    max(value) AS max_memory_bytes
FROM observability.metrics
WHERE metric_name = 'container_memory_working_set_bytes'
  AND timestamp > now() - INTERVAL 5 MINUTE
GROUP BY namespace, pod
ORDER BY max_memory_bytes DESC
LIMIT 20
```

### Container CPU usage

```sql
SELECT
    tags['namespace'] AS namespace,
    tags['pod'] AS pod,
    tags['container'] AS container,
    avg(value) AS avg_cpu_cores
FROM observability.metrics
WHERE metric_name = 'container_cpu_usage_seconds_total'
  AND timestamp > now() - INTERVAL 5 MINUTE
GROUP BY namespace, pod, container
ORDER BY avg_cpu_cores DESC
LIMIT 20
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
