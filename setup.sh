#!/usr/bin/env bash
# ==============================================================================
# Environment Setup Script for Ubuntu
# Installs Docker, kubectl, and Minikube
# Simulates a developer workstation setup
# ==============================================================================
set -e

echo "=============================="
echo "Ubuntu Dev Environment Setup"
echo "=============================="

# ------------------------------------------------------------------------------
# STEP 1: Update the system
# ------------------------------------------------------------------------------
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# ------------------------------------------------------------------------------
# STEP 2: Install dependencies
# ------------------------------------------------------------------------------
echo "Installing required dependencies..."
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# ------------------------------------------------------------------------------
# STEP 3: Install Docker
# ------------------------------------------------------------------------------
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    sudo usermod -aG docker $USER
    echo "Docker installed successfully."
else
    echo "Docker already installed — skipping."
fi

# ------------------------------------------------------------------------------
# STEP 4: Install kubectl
# ------------------------------------------------------------------------------
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    echo "kubectl installed successfully."
else
    echo "kubectl already installed — skipping."
fi

# ------------------------------------------------------------------------------
# STEP 5: Install Minikube
# ------------------------------------------------------------------------------
if ! command -v minikube &> /dev/null; then
    echo "Installing Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    echo "Minikube installed successfully."
else
    echo "Minikube already installed — skipping."
fi

# ------------------------------------------------------------------------------
# STEP 6: Summary
# ------------------------------------------------------------------------------
echo
echo "=============================="
echo "Installation Summary"
echo "=============================="
docker --version 2>/dev/null || echo "Docker not found"
kubectl version --client --short 2>/dev/null || echo "kubectl not found"
minikube version 2>/dev/null || echo "Minikube not found"
echo
echo "💡 You may need to log out and back in for Docker group changes to take effect."
echo "Run: 'minikube start --driver=docker' to launch your local Kubernetes cluster."
echo "=============================="
