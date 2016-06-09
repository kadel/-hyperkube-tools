#!/bin/bash

sudo docker stop hyperkube 
sudo docker rm hyperkube

for id in `docker ps | grep k8s_ | awk '{ print $1 }'`; do
    docker stop $id
    docker rm $id
done

sudo rm -r /var/lib/kubelet
sudo rm -r /var/run/kubernetes


