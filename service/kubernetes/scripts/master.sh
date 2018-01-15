#!/bin/sh
set -e

kubeadm init --config /tmp/master-configuration.yml

kubeadm token create ${token}

[ -d $HOME/.kube ] || mkdir -p $HOME/.kube
ln -s /etc/kubernetes/admin.conf $HOME/.kube/config

until $(curl --output /dev/null --silent --head --fail http://localhost:6443); do
  echo "Waiting for API server to respond"
  sleep 5
done

# install Calico overlay network
kubectl apply -f https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/rbac.yaml # authoriaztions for Calico

curl https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/calico.yaml -o /tmp/calico.yaml # hosted install for Calico (using existant etcd cluster)

sed -i 's|etcd_endpoints: "http://127.0.0.1:2379"|etcd_endpoints: "${etcd_endpoints}"|' /tmp/calico.yaml # fill etcd endpoints
sed -i 's|value: "Always"|value: "Off"|' /tmp/calico.yaml # turn off IpIp tunneling

kubectl apply -f /tmp/calico.yaml # create Calico overlay network

# run kube-proxy in userspace proxy mode (Weave fix)
#kubectl -n kube-system get ds -l 'k8s-app=kube-proxy' -o json \
#  | jq '.items[0].spec.template.spec.containers[0].command |= .+ ["--proxy-mode=userspace"]' \
#  | kubectl apply -f - && kubectl -n kube-system delete pods -l 'k8s-app=kube-proxy'

# change Calico network CIDR to use the one from WireGuard
kubectl -n kube-system get ds -l 'k8s-app=calico-node' -o json \
  | jq '(.items[0].spec.template.spec.containers[0].env) |= map(if .name == "CALICO_IPV4POOL_CIDR" then . + {"value":"${pod_subnet}"} else . end)' \
  | kubectl apply -f - && kubectl -n kube-system delete pods -l 'k8s-app=calico-node'

# force Calico to run on master
kubectl -n kube-system get ds -l 'k8s-app=calico-node' -o json \
  | jq '.items[0].spec.template.spec |= . + {"tolerations":[{"key":"node-role.kubernetes.io/master","effect":"NoSchedule"}]}' \
  | kubectl apply -f - && kubectl -n kube-system delete pods -l 'k8s-app=calico-node'

until $(curl --output /dev/null --silent --head --fail http://localhost:9099/readiness); do
  echo "Waiting for Calico node to respond"
  sleep 5
done
echo "Calico node responds"

until [ $(kubectl get nodes -o jsonpath='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'| tr ';' "\n"  | grep "Ready=True" | wc -l) -ne 3 ]; do
  echo "Waiting for nodes to be running"
  sleep 5
done
echo "Nodes are Ready!"

ETCDCTL_API=3 /opt/etcd/etcdctl --endpoints ${etcd_endpoints} get --from-key --keys-only "" | grep /calico/ipam/v2/host > /tmp/calico-ipam

# See: https://kubernetes.io/docs/admin/authorization/rbac/
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts
