#!/bin/bash

# Parse arguments.
port=6000

while test $# -gt 0; do
  case "$1" in

    --pci-args)
      pci=$2
      vfs=$3
      dpdk_extra="-w ${pci},representor=[${vfs}],dv_flow_en=0,dv_esw_en=0,isolated_mode=1 ${dpdk_extra}"
      shift
      shift
      shift
      ;;

    --pmd-cpu-mask)
      pmd_cpu_mask=$2
      shift
      shift
      ;;

    --port)
      port=$2
      shift
      shift
      ;;

    --help)
      echo "
ovs_container_start.sh [options]: Starting script for ovs container which will configure and start ovs
options:
	--pci-args)	<pci_address> <vfs_range>	A pci address of dpdk interface and range of vfs
							e.g 0000:02:00.0 0-15
							You can reuse this option for another devices
	--pmd-cpu-mask	<core_bitmask>			A core bitmask that sets which cores are used by
							OVS-DPDK for datapath packet processing
							e.g 0xc
	--port)		<port number>			OVS manager port default to 6000

	"
      exit 0
      ;;

   *)
      echo "No such option!!"
      echo "Exitting ...."
      exit 1
  esac
done

# Start ovs.
/usr/share/openvswitch/scripts/ovs-ctl start

# Set ovs manager.
ovs-vsctl set-manager ptcp:"${port}"

# Enable DPDK
ovs-vsctl set Open_vSwitch . other_config:dpdk-init=true

# Add dpdk-extra args.
if [[ -n "${dpdk_extra}" ]]
then
    ovs-vsctl set Open_vSwitch . other_config:dpdk-extra="${dpdk_extra}"
fi

# Add pmd-cpu-mask
if [[ -n "${pmd_cpu_mask}" ]]
then
    ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask="${pmd_cpu_mask}"
fi

# Create br0-ovs bridge
ovs-vsctl add-br br0-ovs -- set bridge br0-ovs datapath_type=netdev

# Sleep forever.
sleep infinity
