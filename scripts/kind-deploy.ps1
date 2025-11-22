#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [string]$ClusterName = "test",
    [string]$Namespace = $(if ($env:NAMESPACE) { $env:NAMESPACE } else { "default" }),
    [string]$ImageTag = "thotogelo/coffeequeue:latest",
    [string]$K8sDirectory = "./k8s"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
}

Write-Section "Ensuring kind cluster '$ClusterName' exists..."

$clusterList = @()
try {
    $clusterList = kind get clusters | Where-Object { $_ }
} catch {
    throw "Failed to list kind clusters. Ensure kind is installed and on PATH. $_"
}

if (-not ($clusterList | Where-Object { $_ -eq $ClusterName })) {
    Write-Host "Creating kind cluster named '$ClusterName'..." -ForegroundColor Yellow
    kind create cluster --name $ClusterName | Out-Host
} else {
    Write-Host "Reusing existing kind cluster '$ClusterName'." -ForegroundColor Green
}

Write-Section "Switching kubectl context to '$Context'..."
kubectl cluster-info --context $Context | Out-Host

Write-Section "Loading image $ImageTag into kind cluster..."
kind load docker-image $ImageTag --name $ClusterName | Out-Host

Write-Section "Applying PostgreSQL manifests..."
kubectl apply -n $Namespace -f (Join-Path $K8sDirectory "postgres-db-init-script.yaml") | Out-Host
kubectl apply -n $Namespace -f (Join-Path $K8sDirectory "postgres-deployment.yaml") | Out-Host
kubectl apply -n $Namespace -f (Join-Path $K8sDirectory "postgres-service.yaml") | Out-Host

Write-Section "Waiting for PostgreSQL deployment to become available..."
kubectl wait --for=condition=available --timeout=120s deployment/postgres -n $Namespace | Out-Host

Write-Section "Resetting postgres init job..."
kubectl delete job postgres-init-job -n $Namespace --ignore-not-found=true | Out-Host
kubectl apply -n $Namespace -f (Join-Path $K8sDirectory "postgres-init-job.yaml") | Out-Host

Write-Section "Waiting for database initialization job to complete..."
kubectl wait --for=condition=complete --timeout=120s job/postgres-init-job -n $Namespace | Out-Host

Write-Section "Deploying CoffeeQueue application..."
kubectl apply -n $Namespace -f (Join-Path $K8sDirectory "coffeequeue-hpa.yaml") | Out-Host
kubectl apply -n $Namespace -f (Join-Path $K8sDirectory "coffeequeue-deployment.yaml") | Out-Host
kubectl apply -n $Namespace -f (Join-Path $K8sDirectory "coffeequeue-service.yaml") | Out-Host

Write-Section "Waiting for coffeequeue-app rollout to finish..."
kubectl rollout status deployment/coffeequeue-app -n $Namespace | Out-Host

Write-Host ""
Write-Host "Deployment to kind cluster '$ClusterName' completed successfully." -ForegroundColor Green

