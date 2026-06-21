#!/bin/bash
set -euo pipefail

# Usage: ./install-lb-controller.sh <env> <cluster_name> <role_arn>
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <env> <cluster_name> <role_arn>"
    exit 1
fi

ENV=$1
CLUSTER_NAME=$2
ROLE_ARN=$3

echo "Installing AWS Load Balancer Controller for $ENV..."

# 1. Install CRDs
echo "Installing CRDs..."
kubectl apply -k "github.com/aws/eks-controllers/alb-ingress-controller/deploy/overlays/aws-load-balancer-controller/crds.yaml"

# 2. Add Helm Repo
echo "Adding Helm repository..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# 3. Install Controller
echo "Installing controller via Helm..."
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

echo "Installation complete. Verify with: kubectl get deployment -n kube-system aws-load-balancer-controller"
