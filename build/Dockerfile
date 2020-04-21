FROM centos:centos7

ENV MLNX_OFED_RHEL7_LIBS "https://linux.mellanox.com/public/repo/mlnx_ofed/latest/rhel7.7/x86_64/UPSTREAM_LIBS/"
ENV MLNX_OFED_VERSION "50100.0"
# ARGS are the arguements for ovs_container_start.sh script you can use --help to check
ENV ARGS "--pci_args 0000:02:00.0 0-3 --port 5678"


RUN yum install -y  python3-libs unbound-libs perl pciutils libnl3 numactl\
    python python-six iproute hostname compat-openssl10 unbound\
    ${MLNX_OFED_RHEL7_LIBS}rdma-core-50mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm\
    ${MLNX_OFED_RHEL7_LIBS}libibverbs-50mlnx1-1.${MLNX_OFED_VERSION}.x86_64.rpm\
    ${MLNX_OFED_RHEL7_LIBS}mlnx-dpdk-19.11.0-1.${MLNX_OFED_VERSION}.x86_64.rpm\
    ${MLNX_OFED_RHEL7_LIBS}openvswitch-2.12.1-1.${MLNX_OFED_VERSION}.x86_64.rpm

ADD ./entrypoint.sh /

ENTRYPOINT "/entrypoint.sh"  ${ARGS}
