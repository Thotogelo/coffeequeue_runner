#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [string]$Namespace = $(if ($env:NAMESPACE) { $env:NAMESPACE } else { "default" }),
    [string]$K8sDirectory = "./k8s",
    [int]$PortForwardLocalPort = 8080,
    [int]$PortForwardRemotePort = 80,
    [switch]$SkipPortForward
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
}

Write-Section "Ensuring namespace '$Namespace' exists..."
try {
    kubectl create namespace $Namespace | Out-Host
} catch {
    Write-Host "Namespace '$Namespace' already exists or could not be created: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Section "Applying PostgreSQL manifests..."
kubectl apply -f (Join-Path $K8sDirectory "postgres-db-init-script.yaml") -n $Namespace | Out-Host
kubectl apply -f (Join-Path $K8sDirectory "postgres-deployment.yaml") -n $Namespace | Out-Host
kubectl apply -f (Join-Path $K8sDirectory "postgres-service.yaml") -n $Namespace | Out-Host

Write-Section "Waiting for PostgreSQL deployment to become available..."
kubectl wait --for=condition=available --timeout=120s deployment/postgres -n $Namespace | Out-Host

Write-Section "Resetting postgres init job..."
kubectl delete job postgres-init-job -n $Namespace --ignore-not-found=true | Out-Host
kubectl apply -f (Join-Path $K8sDirectory "postgres-init-job.yaml") -n $Namespace | Out-Host

Write-Section "Waiting for database initialization job to complete..."
kubectl wait --for=condition=complete --timeout=120s job/postgres-init-job -n $Namespace | Out-Host

Write-Section "Deploying CoffeeQueue application..."
kubectl apply -f (Join-Path $K8sDirectory "coffeequeue-hpa.yaml") -n $Namespace | Out-Host
kubectl apply -f (Join-Path $K8sDirectory "coffeequeue-deployment.yaml") -n $Namespace | Out-Host
kubectl apply -f (Join-Path $K8sDirectory "coffeequeue-service.yaml") -n $Namespace | Out-Host

Write-Section "Waiting for coffeequeue-app rollout to finish..."
kubectl rollout status deployment/coffeequeue-app -n $Namespace | Out-Host

if (-not $SkipPortForward) {
    Write-Section "Starting port-forward on localhost:$PortForwardLocalPort -> service port $PortForwardRemotePort..."
    $job = Start-Job -ScriptBlock {
        param($ns, $localPort, $remotePort)
        kubectl port-forward service/coffeequeue-service "$localPort`:$remotePort" -n $ns
    } -ArgumentList $Namespace, $PortForwardLocalPort, $PortForwardRemotePort

    Write-Host "Port-forward job started (Id=$($job.Id)). Use 'Receive-Job -Id $($job.Id)' to monitor or 'Stop-Job -Id $($job.Id)' to stop." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Deployment to Minikube completed. Access the app at http://localhost:$PortForwardLocalPort" -ForegroundColor Green

