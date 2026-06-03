@echo off
setlocal enabledelayedexpansion

set PROJECT_NAME=ModResorts

set /p IMAGE_TAG_INPUT="Enter image tag (default: latest): "
if "%IMAGE_TAG_INPUT%"=="" (
  set IMAGE_TAG_INPUT=latest
)

for /f "delims=" %%A in ('powershell -Command "'%IMAGE_TAG_INPUT%' .ToLower() -replace '[^a-z0-9]', '-' -replace '^-+', '' -replace '-+$', ''"') do set IMAGE_TAG_SANITIZED=%%A
if "%IMAGE_TAG_SANITIZED%"=="" set IMAGE_TAG_SANITIZED=latest

for /f "delims=" %%A in ('powershell -Command "'%PROJECT_NAME%' .ToLower() -replace '[^a-z0-9]', '-' -replace '^-+', '' -replace '-+$', ''"') do set IMAGE_NAME=%%A

echo Select container registry:
echo 1^) Azure Container Registry ^(ACR^)
echo 2^) Docker Hub
set /p REGISTRY_CHOICE="Enter choice [1-2]: "

if "%REGISTRY_CHOICE%"=="1" (
  set /p ACR_NAME="Enter Azure ACR name (e.g., myregistry): "
  if "!ACR_NAME!"=="" (
    echo ACR name is required
    exit /b 1
  )
  set REGISTRY_URL=!ACR_NAME!.azurecr.io
  echo Logging in to Azure ACR...
  az acr login --name !ACR_NAME!
  if !ERRORLEVEL! neq 0 (
    echo ACR login failed
    exit /b 1
  )
  set FULL_IMAGE_NAME=!REGISTRY_URL!/!IMAGE_NAME!:!IMAGE_TAG_SANITIZED!
) else if "%REGISTRY_CHOICE%"=="2" (
  set /p DOCKER_USERNAME="Enter Docker Hub username: "
  if "!DOCKER_USERNAME!"=="" (
    echo Docker Hub username is required
    exit /b 1
  )
  set /p DOCKER_PASSWORD="Enter Docker Hub password: "
  echo !DOCKER_PASSWORD! | docker login --username !DOCKER_USERNAME! --password-stdin
  if !ERRORLEVEL! neq 0 (
    echo Docker Hub login failed
    exit /b 1
  )
  set FULL_IMAGE_NAME=!DOCKER_USERNAME!/!IMAGE_NAME!:!IMAGE_TAG_SANITIZED!
) else (
  echo Invalid registry choice
  exit /b 1
)

echo Building Docker image: !FULL_IMAGE_NAME!
docker build -f Dockerfile -t !FULL_IMAGE_NAME! .
if !ERRORLEVEL! neq 0 (
  echo Docker build failed
  exit /b 1
)

echo Pushing Docker image: !FULL_IMAGE_NAME!
docker push !FULL_IMAGE_NAME!
if !ERRORLEVEL! neq 0 (
  echo Docker push failed
  exit /b 1
)

echo Image pushed successfully: !FULL_IMAGE_NAME!
