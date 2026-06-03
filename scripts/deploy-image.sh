#!/bin/bash
set -e
set -o pipefail

NAMESPACE="modresorts"

read -rp "Enter Azure resource group name: " RESOURCE_GROUP
if [ -z "$RESOURCE_GROUP" ]; then
  echo "Resource group is required" >&2
  exit 1
fi

read -rp "Enter Azure AKS cluster name: " CLUSTER_NAME
if [ -z "$CLUSTER_NAME" ]; then
  echo "AKS cluster name is required" >&2
  exit 1
fi

read -rp "Enter full Docker image URI (e.g., myregistry.azurecr.io/modresorts:latest): " IMAGE_URI
if [ -z "$IMAGE_URI" ]; then
  echo "Image URI is required" >&2
  exit 1
fi

echo "Configuring kubectl for AKS cluster..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME"

echo "Verifying cluster connectivity..."
kubectl cluster-info >/dev/null

echo "Updating Kubernetes manifests with image URI..."
sed -i "s|{{IMAGE_URI}}|$IMAGE_URI|g" kubernetes/deployment.yaml || true

echo "Applying Kubernetes manifests..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

echo "Waiting for deployment rollout..."
kubectl rollout status deployment/modresorts -n "$NAMESPACE"

echo "Current resources in namespace $NAMESPACE:"
kubectl get pods,svc,ingress -n "$NAMESPACE"

echo "If using the sample ingress, access the app via: http://modresorts.example.com/"
