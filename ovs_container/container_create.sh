#!/bin/bash

# Create ovs container
docker container create \
    --privileged \
    --network host \
    --name ovs_container \
    --restart unless-stopped \
    -v /dev/hugepages:/dev/hugepages \
    -v /forwarder/var/run/virtio-forwarder:/var/run/virtio-forwarder \
    -v /forwarder/var/run/openvswitch/:/var/run/openvswitch/ \
    ovs-docker
