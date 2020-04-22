FROM centos:centos7

ARGS MLNX_OFED_RHEL_LIBS
ARGS MLNX_OFED_VERSION

RUN yum install -y  python3-libs unbound-libs perl pciutils libnl3 numactl\
    python python-six iproute hostname compat-openssl10 unbound\
    ${MLNX_OFED_RHEL_LIBS}rdma-core-50mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm\
    ${MLNX_OFED_RHEL_LIBS}libibverbs-50mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm\
    ${MLNX_OFED_RHEL_LIBS}mlnx-dpdk-19.11.0-1.${MLNX_OFED_VERSION}.x86_64.rpm\
    ${MLNX_OFED_RHEL_LIBS}openvswitch-2.12.1-1.${MLNX_OFED_VERSION}.x86_64.rpm

LABEL ovs.forwarder-name="Containerized OVS Forwarder"

ADD ./entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
