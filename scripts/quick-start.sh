#!/bin/bash
# Quick start script for deploying Globalping Probe

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}"
cat << "EOF"
   _____ _       _           _       _             
  / ____| |     | |         | |     (_)            
 | |  __| | ___ | |__   __ _| |_ __  _ _ __   __ _ 
 | | |_ | |/ _ \| '_ \ / _` | | '_ \| | '_ \ / _` |
 | |__| | | (_) | |_) | (_| | | |_) | | | | | (_| |
  \_____|_|\___/|_.__/ \__,_|_| .__/|_|_| |_|\__, |
                               | |             __/ |
                               |_|            |___/ 
   _____           _          
  |  __ \         | |         
  | |__) | __ ___ | |__   ___ 
  |  ___/ '__/ _ \| '_ \ / _ \
  | |   | | | (_) | |_) |  __/
  |_|   |_|  \___/|_.__/ \___|

EOF
echo -e "${NC}"

echo "Welcome to Globalping Probe Quick Start!"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed${NC}"
    echo "  Please install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo -e "${RED}✗ Helm is not installed${NC}"
    echo "  Please install Helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗ No Kubernetes cluster found${NC}"
    echo "  Please configure kubectl to connect to your cluster"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# Get token
if [ -z "$GLOBALPING_TOKEN" ]; then
    echo -e "${YELLOW}Globalping Token Required${NC}"
    echo "You need a Globalping adoption token to run a probe."
    echo ""
    echo "To get your token:"
    echo "  1. Visit: https://globalping.io"
    echo "  2. Create an account or sign in"
    echo "  3. Copy your adoption token"
    echo ""
    read -p "Enter your Globalping token: " GLOBALPING_TOKEN
    
    if [ -z "$GLOBALPING_TOKEN" ]; then
        echo -e "${RED}✗ Token is required${NC}"
        exit 1
    fi
fi

# Get namespace
read -p "Enter namespace (default: globalping-probe): " NAMESPACE
NAMESPACE=${NAMESPACE:-globalping-probe}

# Get deployment type
echo ""
echo "Choose deployment type:"
echo "  1. DaemonSet (recommended - one probe per node)"
echo "  2. Deployment (specific number of replicas)"
read -p "Enter choice (1 or 2, default: 1): " DEPLOY_CHOICE
DEPLOY_CHOICE=${DEPLOY_CHOICE:-1}

if [ "$DEPLOY_CHOICE" = "2" ]; then
    DEPLOYMENT_TYPE="deployment"
    read -p "Enter number of replicas (default: 1): " REPLICAS
    REPLICAS=${REPLICAS:-1}
else
    DEPLOYMENT_TYPE="daemonset"
fi

# Create namespace
echo ""
echo -e "${YELLOW}Creating namespace...${NC}"
kubectl create namespace "$NAMESPACE" 2>/dev/null || echo "  Namespace already exists"

# Install chart
echo ""
echo -e "${YELLOW}Installing Globalping Probe...${NC}"

HELM_ARGS=(
    "globalping-probe"
    "charts/globalping-probe"
    "--namespace" "$NAMESPACE"
    "--set" "globalpingToken=$GLOBALPING_TOKEN"
    "--set" "deploymentType=$DEPLOYMENT_TYPE"
)

if [ "$DEPLOYMENT_TYPE" = "deployment" ]; then
    HELM_ARGS+=("--set" "replicaCount=$REPLICAS")
fi

helm install "${HELM_ARGS[@]}" --wait --timeout 5m

echo ""
echo -e "${GREEN}✓ Globalping Probe installed successfully!${NC}"
echo ""

# Show status
echo -e "${YELLOW}Current status:${NC}"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=globalping-probe

echo ""
echo -e "${GREEN}Useful commands:${NC}"
echo ""
echo "View logs:"
echo "  kubectl logs -l app.kubernetes.io/name=globalping-probe -n $NAMESPACE -f"
echo ""
echo "Check status:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
echo "Uninstall:"
echo "  helm uninstall globalping-probe -n $NAMESPACE"
echo ""
echo -e "${GREEN}Your probe should now appear in your Globalping dashboard! 🎉${NC}"
echo "Visit: https://globalping.io"

