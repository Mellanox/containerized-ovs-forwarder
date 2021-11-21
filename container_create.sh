#!/bin/bash

if [ ! -z "$MLNX_OFED_LINUX" ]; then
       MLNX_OFED_RHEL_LIBS="/.autodirect/mswg/release/MLNX_OFED/MLNX_OFED_LINUX-${MLNX_OFED_LINUX}/MLNX_OFED_LINUX-${MLNX_OFED_LINUX}-rhel7.7-x86_64/RPMS/"
       MLNX_OFED_VERSION=`ls ${MLNX_OFED_RHEL_LIBS}/openvswitch-d* | rev | cut -d "." -f3 | rev`
fi

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
