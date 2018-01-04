#!/bin/sh
set -e

until $(nc -z ${master_ip} 6443); do
  echo "Waiting for API server to respond"
  sleep 5
done

kubeadm join --discovery-token-unsafe-skip-ca-verification --token=${token} ${master_ip}:6443
