#!/bin/bash

FILE_ROOT=$(dirname "${BASH_SOURCE}")

K8S_VERSION_LATEST=v1.2.4

DNS_REPLICAS=1
DNS_DOMAIN=cluster.local
DNS_SERVER_IP=10.0.0.10


K8S_VERSION=${1:-$K8S_VERSION_LATEST}


sudo docker run -d \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:rw \
    --volume=/var/lib/docker/:/var/lib/docker:rw \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --net=host \
    --pid=host \
    --privileged \
    --name=hyperkube \
    gcr.io/google_containers/hyperkube-amd64:${K8S_VERSION} \
    /hyperkube kubelet \
    --containerized \
    --hostname-override=127.0.0.1 \
    --api-servers=http://localhost:8080 \
    --config=/etc/kubernetes/manifests \
    --cluster-dns=${DNS_SERVER_IP}\
    --cluster-domain=${DNS_DOMAIN} \
    --allow-privileged --v=2

    kubectl config set-cluster hyperkube --server=http://localhost:8080
    kubectl config set-context hyperkube --cluster=test
    kubectl config use-context hyperkube

    echo "Waiting for Kubernetes to start"
    until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do
        echo -n "."
        sleep 5     
    done
    echo ""

    kubectl create namespace kube-system
    cat $FILE_ROOT/skydns.yaml.in | \
        sed -e "s/{{ pillar\['dns_replicas'\] }}/${DNS_REPLICAS}/g;s/{{ pillar\['dns_domain'\] }}/${DNS_DOMAIN}/g;s/{{ pillar\['dns_server'\] }}/${DNS_SERVER_IP}/g" | \
        kubectl create -f-


