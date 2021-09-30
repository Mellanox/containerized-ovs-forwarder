#!/bin/bash
TOPDIR=`git rev-parse --show-toplevel`
cd ${TOPDIR}/build

# Parse arguments
if [ -z "$MLNX_OFED_RHEL_LIBS" ]; then
MLNX_OFED_RHEL_LIBS="https://linux.mellanox.com/public/repo/mlnx_ofed/5.2-2.2.0.0/rhel7.7/x86_64/"
fi
if [ -z "$MLNX_OFED_VERSION" ]; then
MLNX_OFED_VERSION=52220
fi

#MLNX_OFED_RHEL_LIBS="/.autodirect/mswg/release/MLNX_OFED/MLNX_OFED_LINUX-5.3-1.0.0.1.8/MLNX_OFED_LINUX-5.3-1.0.0.1.8-rhel7.7-x86_64/RPMS/"
#MLNX_OFED_VERSION=53100.18

if [ ! -z "$MLNX_OFED_LINUX" ]; then
	MLNX_OFED_RHEL_LIBS="/.autodirect/mswg/release/MLNX_OFED/MLNX_OFED_LINUX-${MLNX_OFED_LINUX}/MLNX_OFED_LINUX-${MLNX_OFED_LINUX}-rhel7.7-x86_64/RPMS/"
	MLNX_OFED_VERSION=`ls ${MLNX_OFED_RHEL_LIBS}/openvswitch-d* | rev | cut -d "." -f3 | rev`
fi

echo $MLNX_OFED_RHEL_LIBS | grep -v autodirect > /dev/null 2>&1
AUTODIRECT=$?

rm -f Dockerfile
if [ "$AUTODIRECT" == "1" ]; then
cp ${MLNX_OFED_RHEL_LIBS}rdma-core-5?mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm .
cp ${MLNX_OFED_RHEL_LIBS}libibverbs-5?mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm .
cp ${MLNX_OFED_RHEL_LIBS}mlnx-dpdk-20.11.0-1.${MLNX_OFED_VERSION}.x86_64.rpm .
cp ${MLNX_OFED_RHEL_LIBS}openvswitch-2.14.1-1.${MLNX_OFED_VERSION}.x86_64.rpm .

ln -s Dockerfile-autodirect Dockerfile

else

ln -s Dockerfile-web Dockerfile

fi

# Create ovs container
echo "Building the ovs-forwarder with MLNX_OFED_VERSION $MLNX_OFED_VERSION"
docker build \
    --build-arg MLNX_OFED_VERSION=$MLNX_OFED_VERSION\
    --build-arg MLNX_OFED_RHEL_LIBS=$MLNX_OFED_RHEL_LIBS\
    -t ovs-forwarder:$MLNX_OFED_VERSION .

if [ "$AUTODIRECT" == "1" ]; then
rm -f rdma-core-5?mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm
rm -f libibverbs-5?mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm
rm -f mlnx-dpdk-20.11.0-1.${MLNX_OFED_VERSION}.x86_64.rpm
rm -f openvswitch-2.14.1-1.${MLNX_OFED_VERSION}.x86_64.rpm
fi
rm -f Dockerfile

cd -
