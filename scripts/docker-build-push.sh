#!/bin/bash

# Variables
IMAGE_NAME="coffeequeue"
DOCKER_REGISTRY="thotogelo" # Replace with your Docker registry
VERSION=$(date +%Y%m%d%H%M)

#Login to docker
echo "dckr_pat_mSXs6MfMuv5sm_Oucj1ztKoAVzY" | docker login -u "thotogelo" --password-stdin

# Build the Docker image
docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:$VERSION .

# Push the Docker image to the registry
#docker push $DOCKER_REGISTRY/$IMAGE_NAME:$VERSION

# Tag the image as 'latest'
docker tag $DOCKER_REGISTRY/$IMAGE_NAME:$VERSION $DOCKER_REGISTRY/$IMAGE_NAME:latest
docker push $DOCKER_REGISTRY/$IMAGE_NAME:latest