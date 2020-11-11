#!/bin/bash


# Create ovs container
docker container create \
    --privileged \
    --network host \
    --name ovs_forwarder_container \
    --restart unless-stopped \
    -v /dev/hugepages:/dev/hugepages \
    -v /var/lib/vhost_sockets/:/var/lib/vhost_sockets/ \
    ovs-forwarder:$MLNX_OFED_VERSION\
    $@
