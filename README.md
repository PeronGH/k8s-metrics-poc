# Kubernetes Metrics POC

A minimal proof-of-concept for collecting Kubernetes container resource metrics for usage billing.

## Architecture

- **Alloy**: Scrapes kubelet cAdvisor endpoints to collect container resource metrics from ALL namespaces
- **Prometheus**: Stores time series data received from Alloy via remote write

Alloy automatically collects metrics from all containers in the cluster - bring your own workloads.

## Metrics Collected

Container resource metrics for usage billing:

- CPU usage (`container_cpu_*`)
- Memory usage (`container_memory_*`)
- Network I/O (`container_network_*`)
- Disk I/O (`container_fs_*`, `container_blkio_*`)

All metrics include labels: `namespace`, `pod`, `node` for billing attribution.

## Deployment

Deploy the metrics stack:

```bash
kubectl apply -k k8s/
```

Delete everything:

```bash
kubectl delete -k k8s/
```

## Access Prometheus

Prometheus UI is accessible via NodePort:

- **<http://localhost:30090>**

## Example Queries

CPU usage by namespace:

```promql
sum(rate(container_cpu_usage_seconds_total[5m])) by (namespace)
```

Memory usage by namespace:

```promql
sum(container_memory_working_set_bytes) by (namespace)
```

List all pods being monitored:

```promql
count(container_memory_working_set_bytes) by (namespace, pod)
```

## Components

- `k8s/00-namespaces.yaml` - Metrics namespace
- `k8s/metrics/prometheus.yaml` - Prometheus StatefulSet and Service
- `k8s/metrics/alloy.yaml` - Alloy Deployment and RBAC
- `k8s/metrics/config.alloy` - Alloy configuration for kubelet scraping
