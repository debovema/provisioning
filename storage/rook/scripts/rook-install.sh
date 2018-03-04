#!/bin/sh

kubectl apply -f /tmp/rook/rook-operator.yaml

while [ ! "$(kubectl get pods -n rook-system | grep Running | wc -l)" -eq "3" ]; do
  echo "Waiting for Rook operator to be running"
done

echo "Rook operator is running"

kubectl apply -f /tmp/rook/rook-cluster.yaml
kubectl apply -f /tmp/rook/rook-storageclass.yaml 
