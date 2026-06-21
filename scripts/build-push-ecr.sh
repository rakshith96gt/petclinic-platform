#!/bin/bash

set -e

# Default environment

ENV="dev"
REGION="ap-south-2"

# Parse arguments

while [[ "$#" -gt 0 ]]; do
case $1 in
--env) ENV="$2"; shift ;;
--region) REGION="$2"; shift ;;
*) echo "Unknown parameter passed: $1"; exit 1 ;;
esac
shift
done

# Validate environment

if [[ "$ENV" != "dev" && "$ENV" != "prod" ]]; then
echo "Error: Environment must be 'dev' or 'prod'."
exit 1
fi

TAG=$(git rev-parse --short HEAD)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/petclinic-${ENV}"

BASE_DIR="/mnt/c/Users/ganas/OneDrive/Desktop/project/spring-petclinic/spring-petclinic-microservices"

echo "Building for environment: ${ENV}"
echo "Target Tag: ${TAG}"
echo "ECR Registry: ${ECR_URL}"

SERVICES=(
"config-server:spring-petclinic-config-server:8888"
"discovery-server:spring-petclinic-discovery-server:8761"
"api-gateway:spring-petclinic-api-gateway:8080"
"customers-service:spring-petclinic-customers-service:8081"
"visits-service:spring-petclinic-visits-service:8082"
"vets-service:spring-petclinic-vets-service:8083"
"genai-service:spring-petclinic-genai-service:8084"
"admin-server:spring-petclinic-admin-server:9090"
)

echo "Step 1: Building JARs..."

for service_info in "${SERVICES[@]}"; do
IFS=':' read -r SERVICE SERVICE_DIR_NAME PORT <<< "$service_info"

SERVICE_DIR="${BASE_DIR}/${SERVICE_DIR_NAME}"

echo "Building ${SERVICE}..."

mvn -f "${SERVICE_DIR}/pom.xml" clean package -DskipTests


done

docker buildx inspect mybuilder >/dev/null 2>&1 || docker buildx create --use --name mybuilder

echo "Step 2: Building and pushing ARM64 images..."

for service_info in "${SERVICES[@]}"; do

IFS=':' read -r SERVICE SERVICE_DIR_NAME PORT <<< "$service_info"

SERVICE_DIR="${BASE_DIR}/${SERVICE_DIR_NAME}"

echo "Processing ${SERVICE}..."

JAR_FILE=$(find "${SERVICE_DIR}/target" -type f -name "*.jar" \
    ! -name "*sources.jar" \
    ! -name "*javadoc.jar" \
    | head -n 1)

if [ -z "$JAR_FILE" ]; then
    echo "ERROR: JAR file not found for ${SERVICE}"
    exit 1
fi

IMAGE_TAG="${ECR_URL}/${SERVICE}:${TAG}"

echo "Building image ${IMAGE_TAG}"

docker buildx build \
    --platform linux/arm64 \
    --build-arg ARTIFACT_NAME="$(basename "$JAR_FILE")" \
    --build-arg EXPOSED_PORT="${PORT}" \
    -f "${BASE_DIR}/docker/Dockerfile" \
    -t "${IMAGE_TAG}" \
    --push \
    "${SERVICE_DIR}"

echo "Successfully pushed ${SERVICE}"

done

echo "All images have been built and pushed successfully."
