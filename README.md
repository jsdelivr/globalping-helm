# Globalping Probe Helm Repository

This is the Helm chart repository for Globalping Probe.

## Usage

Add this repository to Helm:

```bash
helm repo add globalping-probe https://jsdelivr.github.io/globalping-helm
helm repo update
```

## Install Chart

```bash
helm install my-probe globalping-probe/globalping-probe \
  --set globalpingToken=YOUR_TOKEN_HERE \
  --namespace globalping-probe \
  --create-namespace
```

## Available Charts

- **globalping-probe**: Deploy Globalping Probe on Kubernetes

## Documentation

For detailed documentation, visit the [main repository](https://github.com/jsdelivr/globalping-helm).

## Artifact Hub

This repository is available on [Artifact Hub](https://artifacthub.io/).
