# ModResorts Deployment Guide (Azure AKS)

## 1. Overview

This document describes how to build, containerize, and deploy the ModResorts Java EE web application to Azure Kubernetes Service (AKS).

The application is packaged as a WAR and runs on Apache Tomcat inside a Docker container. Kubernetes manifests and helper scripts are provided for deployment.

## 2. Prerequisites

- Docker installed and configured
- Java 8 JDK installed (for local builds if needed)
- Maven installed (for local builds if needed)
- Azure CLI installed and logged in (`az login`)
- kubectl installed and configured
- An Azure subscription with permissions to create AKS and ACR resources

## 3. Project Structure

Key files added for containerization:

- `Dockerfile` – Multi-stage build for the ModResorts WAR on Tomcat
- `docker-compose.yml` – Local development using Docker Compose
- `scripts/build-push.sh` – Linux/macOS script to build and push Docker image
- `scripts/build-push.bat` – Windows script to build and push Docker image
- `kubernetes/namespace.yaml` – Namespace definition
- `kubernetes/deployment.yaml` – Deployment for the application
- `kubernetes/service.yaml` – ClusterIP service
- `kubernetes/ingress.yaml` – Ingress for HTTP routing (Azure Application Gateway)
- `scripts/deploy-image.sh` – Linux/macOS script to deploy to AKS
- `scripts/deploy-image.bat` – Windows script to deploy to AKS

## 4. Local Development with Docker Compose

1. Ensure Docker is running.
2. From the project root, build and start the container:

   ```bash
   docker-compose up --build
   ```

3. Access the application at:

   - `http://localhost:8080/`
   - Health endpoint: `http://localhost:8080/health`

4. To stop the containers:

   ```bash
   docker-compose down
   ```

## 5. Building and Pushing the Docker Image

### 5.1 Linux/macOS

1. Make the script executable:

   ```bash
   chmod +x scripts/build-push.sh
   ```

2. Run the script:

   ```bash
   ./scripts/build-push.sh
   ```

3. Follow prompts to:
   - Choose registry type (Azure ACR or Docker Hub)
   - Provide registry credentials
   - Provide image tag (default `latest`)

### 5.2 Windows

1. Run the batch script from a Developer Command Prompt or PowerShell:

   ```bat
   scripts\build-push.bat
   ```

2. Follow prompts to:
   - Choose registry type (Azure ACR or Docker Hub)
   - Provide registry credentials
   - Provide image tag (default `latest`)

## 6. Azure AKS Deployment

### 6.1 AKS and ACR Setup (High-Level)

1. Create a resource group (if not existing):

   ```bash
   az group create --name my-resource-group --location eastus
   ```

2. Create an AKS cluster (if not existing):

   ```bash
   az aks create \
     --resource-group my-resource-group \
     --name my-aks-cluster \
     --node-count 2 \
     --enable-managed-identity \
     --generate-ssh-keys
   ```

3. (Optional) Create an Azure Container Registry (ACR):

   ```bash
   az acr create --resource-group my-resource-group --name myregistry --sku Basic
   ```

4. Grant AKS access to pull from ACR (if using ACR):

   ```bash
   az aks update -n my-aks-cluster -g my-resource-group --attach-acr myregistry
   ```

## 7. Deploying to AKS

### 7.1 Linux/macOS

1. Ensure the image has been pushed to your registry.
2. Make the deployment script executable:

   ```bash
   chmod +x scripts/deploy-image.sh
   ```

3. Run the script:

   ```bash
   ./scripts/deploy-image.sh
   ```

4. Provide:
   - Azure resource group name
   - AKS cluster name
   - Full image URI (e.g., `myregistry.azurecr.io/modresorts:latest`)

5. The script will:
   - Configure kubectl for the AKS cluster
   - Update the deployment manifest with the image URI
   - Apply namespace, deployment, service, and ingress manifests
   - Wait for the deployment rollout

### 7.2 Windows

1. Ensure the image has been pushed to your registry.
2. Run the deployment script:

   ```bat
   scripts\deploy-image.bat
   ```

3. Provide:
   - Azure resource group name
   - AKS cluster name
   - Full image URI (e.g., `myregistry.azurecr.io/modresorts:latest`)

4. The script will perform the same steps as the Linux/macOS version.

## 8. Accessing the Application on AKS

- The `kubernetes/ingress.yaml` is configured with host `modresorts.example.com`.
- Configure DNS (or /etc/hosts for testing) to point `modresorts.example.com` to your Application Gateway or ingress IP.
- Access the application at:

  - `http://modresorts.example.com/`
  - Health endpoint: `http://modresorts.example.com/health`

## 9. Scaling and Management

- Scale the deployment:

  ```bash
  kubectl scale deployment/modresorts -n modresorts --replicas=3
  ```

- View pods and services:

  ```bash
  kubectl get pods,svc,ingress -n modresorts
  ```

- Perform rolling updates by pushing a new image tag and updating the deployment manifest or re-running the deployment script with the new image URI.

## 10. Configuration and Environment Variables

- The container exposes the following environment variables:
  - `TZ` – Timezone (default `UTC`)
  - `JAVA_OPTS` – JVM options for memory and container awareness

- Add additional environment variables in `kubernetes/deployment.yaml` under `env:` as needed (e.g., database URLs, API keys).

## 11. Security Considerations

- Use private container registries (ACR or private Docker Hub repositories).
- Restrict access to the AKS cluster using Azure RBAC.
- Use Kubernetes Secrets for sensitive configuration (e.g., passwords, API keys).
- Regularly update base images and dependencies to include security patches.

## 12. Troubleshooting

- Check pod logs:

  ```bash
  kubectl logs -l app=modresorts -n modresorts
  ```

- Describe pods and services for more details:

  ```bash
  kubectl describe pod -l app=modresorts -n modresorts
  kubectl describe service modresorts-service -n modresorts
  ```

- If ingress is not working, verify:
  - Ingress controller is installed and running
  - DNS is correctly configured
  - Ingress rules match the service name and port

## 13. Notes

- The application is a Java EE WAR running on Tomcat with Java 8.
- Health checks are provided via the `/health` servlet.
- Adjust resource requests/limits in `kubernetes/deployment.yaml` based on your workload.
