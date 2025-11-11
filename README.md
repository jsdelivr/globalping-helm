# Globalping Probe Helm Repository

This is the Helm chart repository for Globalping Probe.

## Usage

Add this repository to Helm:

```bash
helm repo add globalping https://jsdelivr.github.io/globalping-helm
helm repo update
```

## Install Chart

```bash
helm install globalping-probe globalping/globalping \
  --set globalpingToken=YOUR_TOKEN_HERE \
  --namespace globalping \
  --create-namespace
```

## Available Charts

- **globalping**: Deploy Globalping Probe on Kubernetes

## Documentation

For detailed documentation, visit the [main repository](https://github.com/jsdelivr/globalping-helm).

## Artifact Hub

This repository is available on [Artifact Hub](https://artifacthub.io/).
