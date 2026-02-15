#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [string]$ClusterName = "dev",
    [string]$Namespace = $(if ($env:NAMESPACE) { $env:NAMESPACE } else { "default" }),
    [string]$ImageTag = "ghcr.io/thotogelo/coffeequeue_runner:develop",
    [string]$HelmDeployment = "./charts/coffeequeue",
    [string]$ReleaseName = "coffeequeue_runner"
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

$Context = "kind-$ClusterName"
Write-Section "Switching kubectl context to '$Context'..."
kubectl cluster-info --context $Context | Out-Host

Write-Section "Loading image $ImageTag into kind cluster..."
$hasImage = $false
docker image inspect $ImageTag > $null 2>&1
if ($LASTEXITCODE -eq 0) {
    $hasImage = $true
}

if (-not $hasImage) {
    Write-Host "Image $ImageTag not found locally. Attempting to pull from registry..." -ForegroundColor Yellow
    docker pull $ImageTag | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to pull $ImageTag. If the image is private, authenticate (e.g. 'docker login') or build it locally before running this script." -ForegroundColor Red
        throw "Image $ImageTag not available locally and docker pull failed."
    }
}
kind load docker-image $ImageTag --name $ClusterName | Out-Host

$ImageRepo = $ImageTag
$ImageVersion = "latest"
$lastColon = $ImageTag.LastIndexOf(":")
if ($lastColon -gt -1) {
    $ImageRepo = $ImageTag.Substring(0, $lastColon)
    $ImageVersion = $ImageTag.Substring($lastColon + 1)
}

Write-Section "Deploying CoffeeQueue with Helm..."
helm upgrade --install $ReleaseName $HelmDeployment `
    --namespace $Namespace `
    --create-namespace `
    --set app.image.repository=$ImageRepo `
    --set app.image.tag=$ImageVersion `
    --wait `
    --timeout 120s | Out-Host

Write-Host ""
Write-Host "Deployment to kind cluster '$ClusterName' completed successfully." -ForegroundColor Green

