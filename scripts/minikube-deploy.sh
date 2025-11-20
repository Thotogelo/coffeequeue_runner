#!/bin/bash

# Set the namespace
NAMESPACE="default"

# Create the namespace if it doesn't exist
kubectl create namespace $NAMESPACE || echo "Namespace $NAMESPACE already exists."

# Apply the Kubernetes configurations
# Deploy PostgreSQL first
kubectl apply -f ./k8s/postgres-db-init-script.yaml -n $NAMESPACE
kubectl apply -f ./k8s/postgres-deployment.yaml -n $NAMESPACE
kubectl apply -f ./k8s/postgres-service.yaml -n $NAMESPACE

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/postgres -n $NAMESPACE

# Delete any existing init job to ensure fresh initialization
kubectl delete job postgres-init-job -n $NAMESPACE --ignore-not-found=true

# Apply the database initialization job
kubectl apply -f ./k8s/postgres-init-job.yaml -n $NAMESPACE

# Wait for the init job to complete
echo "Waiting for database initialization to complete..."
kubectl wait --for=condition=complete --timeout=120s job/postgres-init-job -n $NAMESPACE

# Deploy the application
kubectl apply -f ./k8s/coffeequeue-hpa.yaml -n $NAMESPACE
kubectl apply -f ./k8s/coffeequeue-deployment.yaml -n $NAMESPACE
kubectl apply -f ./k8s/coffeequeue-service.yaml -n $NAMESPACE

# Get the status of the deployment
kubectl rollout status deployment/coffeequeue-app -n $NAMESPACE

# Optional: Forward the service port to access the application locally
kubectl port-forward service/coffeequeue-service 8080:80 -n $NAMESPACE &

echo "Deployment to Minikube completed. Access the application at http://localhost:8080"