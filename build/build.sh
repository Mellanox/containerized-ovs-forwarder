#!/bin/bash

# Parse arguments
MLNX_OFED_RHEL_LIBS="https://linux.mellanox.com/public/repo/mlnx_ofed/5.2-2.2.0.0/rhel7.7/x86_64/"
MLNX_OFED_VERSION=52220

# Create ovs container
echo "Building the ovs-forwarder with MLNX_OFED_VERSION $MLNX_OFED_VERSION"
docker build \
    --build-arg MLNX_OFED_VERSION=$MLNX_OFED_VERSION\
    --build-arg MLNX_OFED_RHEL_LIBS=$MLNX_OFED_RHEL_LIBS\
    -t ovs-forwarder:$MLNX_OFED_VERSION .
