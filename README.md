# Globalping Probe Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/globalping-probe)](https://artifacthub.io/packages/helm/globalping-probe/globalping-probe)
[![License](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://opensource.org/licenses/MPL-2.0)

Run your own [Globalping Probe](https://github.com/jsdelivr/globalping-probe) on Kubernetes.

## What's This?

Globalping lets you run network measurements (ping, traceroute, DNS, HTTP, MTR) from anywhere in the world. Deploy this chart to contribute your probe to the network and use it for your own measurements.

Get started at [globalping.io](https://globalping.io)

## Quick Install

```bash
# Get your token from globalping.io first

helm repo add globalping https://jsdelivr.github.io/globalping-helm
helm repo update

helm install globalping-probe globalping/globalping \
  --set globalpingToken="YOUR_TOKEN" \
  --namespace globalping \
  --create-namespace

# Check if it's running
kubectl get pods -n globalping
kubectl logs -l app.kubernetes.io/name=globalping-probe -n globalping -f
```

Your probe should appear in your Globalping dashboard within a minute or two.

## What You Need

- Kubernetes 1.19+
- Helm 3.2.0+
- Globalping token from [globalping.io](https://globalping.io)

## Common Configurations

**Run specific number of probes:**
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

**Limit resources:**
```bash
helm install globalping-probe globalping/globalping \
  --set globalpingToken="YOUR_TOKEN" \
  --set resources.limits.cpu=500m \
  --set resources.limits.memory=512Mi \
  --namespace globalping \
  --create-namespace
```

See [chart README](charts/globalping-probe/README.md) for all options.

## Managing Your Probe

**Upgrade:**
```bash
helm repo update
helm upgrade globalping-probe globalping/globalping \
  --namespace globalping \
  --reuse-values
```

**View logs:**
```bash
kubectl logs -l app.kubernetes.io/name=globalping-probe -n globalping -f
```

**Uninstall:**
```bash
helm uninstall globalping-probe --namespace globalping
```

## FAQ

**Why does it need hostNetwork?**  
ICMP packets (ping/traceroute) require direct network access. The chart enables this by default.

**Can I run multiple probes?**  
Yes. Default is DaemonSet mode (one probe per node). Or use Deployment mode with `replicaCount`.

**Where are my probes?**  
Check your [Globalping dashboard](https://globalping.io). They show up within a minute.

**Something not working?**  
Check pod status: `kubectl describe pod -n globalping`  
Check logs: `kubectl logs -l app.kubernetes.io/name=globalping-probe -n globalping`

## Publishing Your Own Chart

If you're hosting this chart yourself:

1. **Update placeholders** in `.github/cr.yaml`, `artifacthub-repo.yml`, and READMEs with your GitHub username

2. **Enable GitHub Pages** in repo Settings → Pages:
   - Source: `gh-pages` branch
   - Folder: `/ (root)`

3. **Run setup workflow:**
   ```bash
   gh workflow run pages.yaml
   ```

4. **Register on Artifact Hub:**
   - Sign in with GitHub at [artifacthub.io](https://artifacthub.io)
   - Add repository: `https://YOUR_USERNAME.github.io/globalping-helm`

5. **Release:** Just commit to master and automation handles the rest

**Troubleshooting:**
- Pages not loading? Check Actions tab for workflow errors
- Chart not on Artifact Hub? Wait 30 minutes for scanning
- Need custom domain? Add CNAME record and create `CNAME` file in gh-pages branch

## More Info

- [Globalping Platform](https://globalping.io)
- [Probe Source Code](https://github.com/jsdelivr/globalping-probe)
- [Chart Configuration](charts/globalping-probe/README.md)

## License

Mozilla Public License 2.0 - see [LICENSE](LICENSE)
