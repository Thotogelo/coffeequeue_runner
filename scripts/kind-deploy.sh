#!/bin/bash

# Set the name of the Kubernetes cluster
CLUSTER_NAME=test

# Set namespace (default to 'default' if not provided)
NAMESPACE=${NAMESPACE:-default}

# Create a kind cluster if it doesn't exist
 if ! kind get clusters | grep -q $CLUSTER_NAME; then
     echo "Creating kind cluster named $CLUSTER_NAME..."
     kind create cluster --name $CLUSTER_NAME
 fi

# Set cluster
kubectl cluster-info --context kind-test

# Load the Docker image into the kind cluster
kind load docker-image thotogelo/coffeequeue:latest --name $CLUSTER_NAME

# Apply the Kubernetes configurations
# Initialize DB ConfigMap
# ./scripts/db-configmap.sh
kubectl apply -n $NAMESPACE -f ./k8s/postgres-db-init-script.yaml
kubectl apply -n $NAMESPACE -f ./k8s/postgres-deployment.yaml
kubectl apply -n $NAMESPACE -f ./k8s/postgres-service.yaml

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/postgres -n $NAMESPACE

# Delete any existing init job to ensure fresh initialization
kubectl delete job postgres-init-job -n $NAMESPACE --ignore-not-found=true

# Apply the database initialization job
kubectl apply -n $NAMESPACE -f ./k8s/postgres-init-job.yaml

# Wait for the init job to complete
echo "Waiting for database initialization to complete..."
kubectl wait --for=condition=complete --timeout=120s job/postgres-init-job -n $NAMESPACE

# Deploy the application
kubectl apply -n $NAMESPACE -f ./k8s/coffeequeue-hpa.yaml
kubectl apply -n $NAMESPACE -f ./k8s/coffeequeue-deployment.yaml
kubectl apply -n $NAMESPACE -f ./k8s/coffeequeue-service.yaml


# Get the status of the deployment
kubectl rollout status deployment/coffeequeue-app -n $NAMESPACE

# Optional: Forward the service port to access the application
#kubectl port-forward service/coffeequeue-service 8080:80 -n $NAMESPACE &

echo "Deployment to kind cluster completed...."