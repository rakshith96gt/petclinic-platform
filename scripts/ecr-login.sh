#!/bin/bash

# Default region
REGION="ap-south-2"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --region) REGION="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "Fetching AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

if [ -z "$ACCOUNT_ID" ]; then
    echo "Error: Could not retrieve AWS Account ID. Please ensure you are authenticated with AWS."
    exit 1
fi

ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "Logging into ECR registry: ${ECR_URL} in region ${REGION}..."
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ECR_URL}"

if [ $? -eq 0 ]; then
    echo "Successfully logged into ECR."
else
    echo "Error: Failed to log into ECR."
    exit 1
fi
