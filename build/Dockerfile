FROM centos:centos7

ARG MLNX_OFED_RHEL_LIBS
ARG MLNX_OFED_VERSION

RUN yum install -y  python3-libs unbound-libs perl pciutils libnl3 numactl\
    python3 python3-six iproute hostname compat-openssl10 unbound\
    && yum install -y \
    ${MLNX_OFED_RHEL_LIBS}rdma-core-52mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm\
    ${MLNX_OFED_RHEL_LIBS}libibverbs-52mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm\
    ${MLNX_OFED_RHEL_LIBS}mlnx-dpdk-20.11.0-1.${MLNX_OFED_VERSION}.x86_64.rpm\
    ${MLNX_OFED_RHEL_LIBS}openvswitch-2.14.1-1.${MLNX_OFED_VERSION}.x86_64.rpm

LABEL ovs.forwarder-name="Containerized OVS Forwarder"

ADD ./entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
