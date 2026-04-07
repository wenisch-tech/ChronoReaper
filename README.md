# k8s-ttl-operator

A **Kubernetes Operator** (built with [Quarkus](https://quarkus.io) and the
[Java Operator SDK](https://javaoperatorsdk.io)) that automatically deletes
any Kubernetes resource whose `wenisch.tech/ttl` annotation timestamp has passed.

---

## Overview

Add the annotation `wenisch.tech/ttl` with an ISO-8601 UTC timestamp to **any**
Kubernetes resource. When that timestamp is crossed, the operator automatically
deletes the resource.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-temp-pod
  annotations:
    wenisch.tech/ttl: "2025-12-31T23:59:59Z"   # delete after this UTC instant
spec:
  containers:
    - name: alpine
      image: alpine:latest
      command: ["sleep", "infinity"]
```

### Supported resource types

| Category       | Resources |
|----------------|-----------|
| Workloads      | `Pod`, `Deployment`, `ReplicaSet`, `StatefulSet`, `DaemonSet`, `Job`, `CronJob` |
| Networking     | `Service`, `Ingress` |
| Configuration  | `ConfigMap`, `Secret`, `ServiceAccount` |
| Cluster-scoped | `Namespace`, `CustomResourceDefinition`, `ClusterRole`, `ClusterRoleBinding` |
| Custom resources | **All** installed CRDs are discovered dynamically |

---

## Quick start

### Install via Helm

```bash
helm install k8s-ttl-operator helm/k8s-ttl-operator \
  --namespace k8s-ttl-operator \
  --create-namespace
```

Override the check interval and enable dry-run mode:

```bash
helm install k8s-ttl-operator helm/k8s-ttl-operator \
  --namespace k8s-ttl-operator \
  --create-namespace \
  --set operator.checkInterval=30s \
  --set operator.dryRun=true
```

### Install via OLM (OperatorHub)

Install [OLM](https://olm.operatorframework.io/docs/getting-started/) if it is
not already present:

```bash
operator-sdk olm install
```

Apply the bundle:

```bash
kubectl apply -f bundle/manifests/
```

Or deploy directly from [OperatorHub.io](https://operatorhub.io).

---

## Configuration

| Environment variable / Helm value | Default | Description |
|-----------------------------------|---------|-------------|
| `TTL_CHECK_INTERVAL` / `operator.checkInterval` | `60s` | Polling interval (ISO-8601 duration) |
| `TTL_DRY_RUN` / `operator.dryRun` | `false` | Log deletions without executing them |

### `application.properties` keys (advanced)

| Key | Default | Description |
|-----|---------|-------------|
| `ttl.check.interval` | `60s` | Same as above |
| `ttl.dry-run` | `false` | Same as above |

---

## Observability

### Health checks

| Probe     | Path               | Port |
|-----------|--------------------|------|
| Liveness  | `/q/health/live`   | 8081 |
| Readiness | `/q/health/ready`  | 8081 |

### Prometheus metrics (port `8081`, path `/q/metrics`)

| Metric | Description |
|--------|-------------|
| `ttl_operator_resources_deleted_total` | Total resources deleted |
| `ttl_operator_errors_total` | Total errors encountered |

---

## Development

### Prerequisites

- Java 17+
- Apache Maven 3.9+

### Build

```bash
mvn package -DskipTests
```

### Run tests

```bash
mvn test
```

### Run locally (dev mode with hot-reload)

```bash
mvn quarkus:dev
```

> **Note:** Running locally requires either a reachable `~/.kube/config` or the
> `KUBERNETES_SERVICE_HOST` env var (in-cluster). Set
> `quarkus.kubernetes-client.devservices.enabled=false` when running outside a
> cluster.

### Build container image

```bash
docker build -t wenischtech/k8s-ttl-operator:1.0.0 .
```

---

## Repository layout

```
k8s-ttl-operator/
├── src/
│   ├── main/java/tech/wenisch/operator/
│   │   ├── TtlOperatorApplication.java   # Quarkus entry point
│   │   └── TtlController.java            # Core TTL-check logic
│   └── main/resources/
│       └── application.properties
├── helm/k8s-ttl-operator/                # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── serviceaccount.yaml
│       ├── clusterrole.yaml
│       ├── clusterrolebinding.yaml
│       └── service.yaml
├── bundle/                               # OLM bundle (OperatorHub.io)
│   ├── manifests/
│   │   └── k8s-ttl-operator.v1.0.0.clusterserviceversion.yaml
│   ├── metadata/
│   │   └── annotations.yaml
│   ├── tests/scorecard/config.yaml
│   └── Dockerfile
├── Dockerfile                            # Operator container image
└── pom.xml
```

---

## OLM / OperatorHub.io publishing

1. **Validate the bundle** with the Operator SDK scorecard:
   ```bash
   operator-sdk scorecard bundle/
   ```

2. **Build and push the bundle image**:
   ```bash
   docker build -t wenischtech/k8s-ttl-operator-bundle:1.0.0 bundle/
   docker push wenischtech/k8s-ttl-operator-bundle:1.0.0
   ```

3. **Submit to OperatorHub.io** by following the
   [contribution guide](https://operatorhub.io/contribute).

---

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
