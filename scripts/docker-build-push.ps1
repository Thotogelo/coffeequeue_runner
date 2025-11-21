#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [string]$ImageName = "coffeequeue",
    [string]$DockerRegistry = "thotogelo",
    [string]$DockerUsername = "thotogelo",
    [string]$Version = $(Get-Date -Format "yyyyMMddHHmm"),
    [string]$DockerfileContext = ".",
    [string]$DockerPassword = "dckr_pat_mSXs6MfMuv5sm_Oucj1ztKoAVzY",
    [switch]$SkipLogin,
    [switch]$PushVersion,
    [switch]$SkipLatestPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Cyan
}

$imageBase = "$DockerRegistry/$ImageName"
$versionTag = "{0}:{1}" -f $imageBase, $Version
$latestTag = "{0}:latest" -f $imageBase

if (-not $SkipLogin) {
    if (-not $DockerPassword) {
        throw "Provide -DockerPassword or set the DOCKER_PASSWORD environment variable to login."
    }

    Write-Section "Logging into Docker registry '$DockerRegistry' as '$DockerUsername'..."
    $DockerPassword | docker login -u $DockerUsername --password-stdin | Out-Host
}

Write-Section "Building Docker image $versionTag..."
docker build -t $versionTag $DockerfileContext | Out-Host

if ($PushVersion) {
    Write-Section "Pushing tagged image $versionTag..."
    docker push $versionTag | Out-Host
}

Write-Section "Tagging image as $latestTag..."
docker tag $versionTag $latestTag | Out-Host

if (-not $SkipLatestPush) {
    Write-Section "Pushing latest tag $latestTag..."
    docker push $latestTag | Out-Host
}

Write-Host ""
Write-Host "Docker image build complete. Latest tag: $latestTag" -ForegroundColor Green

