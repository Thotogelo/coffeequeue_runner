#!/bin/bash

# Create a ConfigMap from the file
kubectl create configmap db-init-script --from-file=./createSchema.sql
echo "ConfigMap 'db-init-script' created with 'createSchema.sql'"

# Verify the ConfigMap
kubectl get configmap db-init-script -o yaml