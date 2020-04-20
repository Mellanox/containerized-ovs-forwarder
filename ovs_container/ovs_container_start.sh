#!/bin/bash

# Parse arguments.
port=5678

while test $# -gt 0; do
  case "$1" in

    --pci_args)
      pci=$2
      vfs=$3
      dpdk_extra="-w ${pci},representor=[${vfs}],dv_flow_en=0,dv_esw_en=0,isolated_mode=1 ${dpdk_extra}"
      shift
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
	--pci_args)	<pci_address> <vfs_range>	A pci address of dpdk interface and range of vfs
							e.g 0000:02:00.0 0-15
							You can reuse this option for another devices
	--port)		<port number>			OVS manager port default to 

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

# Enable DPDK and add dpdk-extra args.
ovs-vsctl set Open_vSwitch . other_config:dpdk-extra="${dpdk_extra}"
ovs-vsctl set Open_vSwitch . other_config:dpdk-init=true

# Sleep forever.
sleep infinity
