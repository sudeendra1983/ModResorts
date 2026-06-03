@echo off
setlocal

set NAMESPACE=modresorts

set /p RESOURCE_GROUP="Enter Azure resource group name: "
if "%RESOURCE_GROUP%"=="" (
  echo Resource group is required
  exit /b 1
)

set /p CLUSTER_NAME="Enter Azure AKS cluster name: "
if "%CLUSTER_NAME%"=="" (
  echo AKS cluster name is required
  exit /b 1
)

set /p IMAGE_URI="Enter full Docker image URI (e.g., myregistry.azurecr.io/modresorts:latest): "
if "%IMAGE_URI%"=="" (
  echo Image URI is required
  exit /b 1
)

echo Configuring kubectl for AKS cluster...
az aks get-credentials --resource-group %RESOURCE_GROUP% --name %CLUSTER_NAME%
if %ERRORLEVEL% neq 0 (
  echo Failed to get AKS credentials
  exit /b 1
)

echo Verifying cluster connectivity...
kubectl cluster-info >nul
if %ERRORLEVEL% neq 0 (
  echo Failed to connect to cluster
  exit /b 1
)

echo Updating Kubernetes manifests with image URI...
powershell -Command "(Get-Content 'kubernetes/deployment.yaml') -replace '{{IMAGE_URI}}', '%IMAGE_URI%' | Set-Content 'kubernetes/deployment.yaml'"

if %ERRORLEVEL% neq 0 (
  echo Failed to update deployment.yaml
  exit /b 1
)

echo Applying Kubernetes manifests...
kubectl apply -f kubernetes/namespace.yaml
if %ERRORLEVEL% neq 0 (
  echo Failed to apply namespace.yaml
  exit /b 1
)

kubectl apply -f kubernetes/deployment.yaml
if %ERRORLEVEL% neq 0 (
  echo Failed to apply deployment.yaml
  exit /b 1
)

kubectl apply -f kubernetes/service.yaml
if %ERRORLEVEL% neq 0 (
  echo Failed to apply service.yaml
  exit /b 1
)

kubectl apply -f kubernetes/ingress.yaml
if %ERRORLEVEL% neq 0 (
  echo Failed to apply ingress.yaml
  exit /b 1
)

echo Waiting for deployment rollout...
kubectl rollout status deployment/modresorts -n %NAMESPACE%

if %ERRORLEVEL% neq 0 (
  echo Deployment rollout failed
  exit /b 1
)

echo Current resources in namespace %NAMESPACE%:
kubectl get pods,svc,ingress -n %NAMESPACE%

echo If using the sample ingress, access the app via: http://modresorts.example.com/
