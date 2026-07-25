#!/bin/bash
set -e

kubectl apply -f namespace.yml
kubectl apply -f pv.yml
kubectl apply -f pvc.yml
kubectl apply -f configMap.yml
kubectl apply -f secret.yml
kubectl apply -f deployment.yml
kubectl apply -f hpa.yml
kubectl apply -f clusterIp.yml
kubectl apply -f nodeport.yml

echo "All todoapp resources have been applied."
kubectl -n todoapp get all