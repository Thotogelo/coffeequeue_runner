#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [string]$ConfigMapName = "db-init-script",
    [string]$ScriptPath = "./createSchema.sql",
    [string]$Namespace = $(if ($env:NAMESPACE) { $env:NAMESPACE } else { "default" }),
    [switch]$Replace
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
}

if ($Replace) {
    Write-Section "Deleting existing ConfigMap '$ConfigMapName' in namespace '$Namespace' (if present)..."
    kubectl delete configmap $ConfigMapName -n $Namespace --ignore-not-found=true | Out-Host
}

Write-Section "Creating ConfigMap '$ConfigMapName' from '$ScriptPath'..."
kubectl create configmap $ConfigMapName --from-file=$ScriptPath -n $Namespace | Out-Host

Write-Section "Verifying ConfigMap contents..."
kubectl get configmap $ConfigMapName -n $Namespace -o yaml | Out-Host

Write-Host ""
Write-Host "ConfigMap '$ConfigMapName' is ready." -ForegroundColor Green

