#!/bin/bash
set -e
set -o pipefail

PROJECT_NAME="ModResorts"

read -rp "Enter image tag (default: latest): " IMAGE_TAG_INPUT
IMAGE_TAG_SANITIZED=$(echo "${IMAGE_TAG_INPUT:-latest}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//')
if [ -z "$IMAGE_TAG_SANITIZED" ]; then
  IMAGE_TAG_SANITIZED="latest"
fi

IMAGE_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//')

echo "Select container registry:"
echo "1) Azure Container Registry (ACR)"
echo "2) Docker Hub"
read -rp "Enter choice [1-2]: " REGISTRY_CHOICE

if [ "$REGISTRY_CHOICE" = "1" ]; then
  read -rp "Enter Azure ACR name (e.g., myregistry): " ACR_NAME
  if [ -z "$ACR_NAME" ]; then
    echo "ACR name is required" >&2
    exit 1
  fi
  REGISTRY_URL="$ACR_NAME.azurecr.io"
  echo "Logging in to Azure ACR..."
  az acr login --name "$ACR_NAME"
  FULL_IMAGE_NAME="$REGISTRY_URL/$IMAGE_NAME:$IMAGE_TAG_SANITIZED"
elif [ "$REGISTRY_CHOICE" = "2" ]; then
  read -rp "Enter Docker Hub username: " DOCKER_USERNAME
  if [ -z "$DOCKER_USERNAME" ]; then
    echo "Docker Hub username is required" >&2
    exit 1
  fi
  read -rsp "Enter Docker Hub password: " DOCKER_PASSWORD
  echo
  echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin
  FULL_IMAGE_NAME="$DOCKER_USERNAME/$IMAGE_NAME:$IMAGE_TAG_SANITIZED"
else
  echo "Invalid registry choice" >&2
  exit 1
fi

echo "Building Docker image: $FULL_IMAGE_NAME"
docker build -f Dockerfile -t "$FULL_IMAGE_NAME" .

echo "Pushing Docker image: $FULL_IMAGE_NAME"
docker push "$FULL_IMAGE_NAME"

echo "Image pushed successfully: $FULL_IMAGE_NAME"
