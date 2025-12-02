# Globalping Probe Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/globalping-probe)](https://artifacthub.io/packages/helm/globalping-probe/globalping-probe)
[![License](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://opensource.org/licenses/MPL-2.0)

Helm chart for deploying [Globalping Probe](https://github.com/jsdelivr/globalping-probe) on Kubernetes.

## What You Need

- Kubernetes 1.19+
- Helm 3.2.0+
- Adoption token from [globalping.io](https://globalping.io)

## Installation

```bash
# Add repo
helm repo add globalping https://jsdelivr.github.io/globalping-helm
helm repo update

# Install
helm install globalping-probe globalping/globalping \
  --set globalpingToken="YOUR_TOKEN" \
  --namespace globalping \
  --create-namespace

# Check status
kubectl get pods -n globalping
kubectl logs -l app.kubernetes.io/instance=globalping-probe -n globalping -f
```

## Common Configurations

**Run as Deployment instead of DaemonSet:**
```bash
helm install globalping-probe globalping/globalping \
  --set globalpingToken="YOUR_TOKEN" \
  --set deploymentType=deployment \
  --set replicaCount=3 \
  --namespace globalping \
  --create-namespace
```

**Keep probe UUID across restarts:**
```bash
helm install globalping-probe globalping/globalping \
  --set globalpingToken="YOUR_TOKEN" \
  --set persistence.enabled=true \
  --namespace globalping \
  --create-namespace
```

**Use JSON logs with debug output:**
```bash
helm install globalping-probe globalping/globalping \
  --set globalpingToken="YOUR_TOKEN" \
  --set env.logFormat=json \
  --set env.debug=true \
  --namespace globalping \
  --create-namespace
```

## Configuration Options

Here are the main options you can configure. For the full list, check `values.yaml`.

### Basic Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `globalpingToken` | Adoption token for your account | `""` |
| `deploymentType` | `daemonset` or `deployment` | `daemonset` |
| `replicaCount` | Pods created when using `deployment` mode | `1` |

### Image

| Setting | Description | Default |
|---------|-------------|---------|
| `image.repository` | Container image | `globalping/globalping-probe` |
| `image.tag` | Image tag (empty uses chart appVersion/latest) | `""` |
| `image.pullPolicy` | Pull policy | `Always` |

### Environment

| Setting | Description | Default |
|---------|-------------|---------|
| `env.debug` | Enable verbose probe logs | `false` |
| `env.logFormat` | `text` or `json` log output | `text` |
| `env.extra` | Additional env vars (`[{name,value}]`) | `[]` |

### Resources

| Setting | Description | Default |
|---------|-------------|---------|
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |

### Scheduling & Rollouts

| Setting | Description | Default |
|---------|-------------|---------|
| `nodeSelector` | Restrict probe pods to specific nodes | `{}` |
| `tolerations` | Allow scheduling on tainted nodes | `[]` |
| `affinity` | Custom affinity/anti-affinity rules | `{}` |
| `updateStrategy.type` | Workload update strategy | `RollingUpdate` |
| `updateStrategy.rollingUpdate.maxUnavailable` | Pods allowed to be unavailable during update | `1` |
| `updateStrategy.rollingUpdate.maxSurge` | Extra pods during deployment updates | `1` |

### Network & Security

| Setting | Description | Default |
|---------|-------------|---------|
| `network.hostNetwork` | Use node network namespace (needed for ICMP) | `true` |
| `network.dnsPolicy` | DNS policy to pair with host networking | `ClusterFirstWithHostNet` |
| `networkPolicy.enabled` | Emit a basic egress NetworkPolicy | `false` |
| `networkPolicy.egress` | Allowed destinations when policy is enabled | Globalping API + DNS |
| `securityContext.runAsNonRoot` | Force a non-root UID | `false` |
| `securityContext.capabilities.add` | Linux capabilities granted | `["NET_RAW"]` |

### Storage

| Setting | Description | Default |
|---------|-------------|---------|
| `persistence.enabled` | Persist probe ID across restarts | `false` |
| `persistence.size` | PersistentVolumeClaim size | `1Gi` |
| `persistence.storageClassName` | Storage class override | `""` |
| `persistence.accessMode` | PVC access mode | `ReadWriteOnce` |

### Health Checks

| Setting | Description | Default |
|---------|-------------|---------|
| `livenessProbe.enabled` | Enable liveness probe | `true` |
| `livenessProbe.exec.command` | Custom command for liveness check | `["sh", "-c", "grep -q node /proc/*/comm 2>/dev/null \|\| exit 1"]` |
| `readinessProbe.enabled` | Enable readiness probe | `true` |
| `readinessProbe.exec.command` | Custom command for readiness check | `["sh", "-c", "grep -q node /proc/*/comm 2>/dev/null \|\| exit 1"]` |

The default probe commands use `/proc` filesystem to check for the node process, which works in minimal container images without additional dependencies.

## Why hostNetwork?

The probe needs `hostNetwork: true` to send ICMP packets directly (for ping/traceroute). Without it, those measurements won't work. HTTP and DNS measurements work fine without it, but you'd lose a lot of functionality.

## Node Selection

Run probes only on specific nodes:

```yaml
nodeSelector:
  node-role.kubernetes.io/worker: "true"
```

Allow probes on tainted nodes:

```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "monitoring"
    effect: "NoSchedule"
```

## Upgrading

```bash
helm repo update
helm upgrade globalping-probe globalping/globalping \
  --namespace globalping \
  --reuse-values
```

Change specific values:

```bash
helm upgrade globalping-probe globalping/globalping \
  --namespace globalping \
  --set resources.limits.memory=1Gi \
  --reuse-values
```

## Uninstalling

```bash
helm uninstall globalping-probe --namespace globalping

# If you enabled persistence, also delete the PVC
kubectl delete pvc -l app.kubernetes.io/instance=globalping-probe -n globalping
```

## Troubleshooting

**Probe not adopting?**

Check your token:
```bash
kubectl get secret -n globalping -o jsonpath='{.data.gp-adoption-token}' | base64 -d
```

Check logs for auth errors:
```bash
kubectl logs -l app.kubernetes.io/instance=globalping-probe -n globalping | grep -i "adopt\|auth"
```

**ICMP measurements failing?**

Make sure `hostNetwork` is enabled and `NET_RAW` capability is set:
```bash
kubectl get daemonset -n globalping -o yaml | grep -A 5 "hostNetwork\|capabilities"
```

Test manually:
```bash
kubectl exec -it <pod-name> -n globalping -- ping -c 3 8.8.8.8
```

**Pods not starting?**

Check events:
```bash
kubectl describe pod -n globalping
kubectl get events -n globalping --sort-by='.lastTimestamp'
```

**High resource usage?**

Check current usage:
```bash
kubectl top pod -l app.kubernetes.io/instance=globalping-probe -n globalping
```

Increase limits if needed:
```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
```

**Probe UUID keeps changing?**

Enable persistence:
```yaml
persistence:
  enabled: true
  size: 1Gi
```

## Security Notes

- Tokens are stored in Kubernetes Secrets
- Runs as root by default (required for ICMP)
- Has NET_RAW capability (required for ping/traceroute)
- Does not create cluster-wide RBAC objects
- Optional NetworkPolicy support for outbound control

For production, consider:
- Enabling network policies
- Using external secret managers (Vault, Sealed Secrets)
- Setting resource limits appropriate for your environment

## More Info

- [Globalping Platform](https://globalping.io)
- [Probe Source Code](https://github.com/jsdelivr/globalping-probe)
- [Globalping API](https://github.com/jsdelivr/globalping)

## License

Mozilla Public License 2.0. See [LICENSE](../../LICENSE) for details.
