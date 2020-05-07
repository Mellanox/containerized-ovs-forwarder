#!/usr/bin/env python

from ovs_module.ovsdb import ovsdb_lib
from ovs_module.containerovsdb import ovsdb_lib as containerovsdb_lib


def main():

    try:
        # Connect to OVS inside container
        container_ovs = containerovsdb_lib.BaseOVS(connection='tcp:127.0.0.1:6000')

        host_ovs = ovsdb_lib.BaseOVS(connection='tcp:127.0.0.1:6001')

        # Add bridge to ovs
        container_ovs.add_ovs_bridge("br0-ovs", "netdev")

        # Create vdpa port
        container_ovs.create_ovs_vif_port("br0-ovs",
                                          "vdpa0",
                                          "dpdkvdpa",
                                          "0000:02:00.1", "0000:02:02.2", 0,
                                          "/var/run/virtio-forwarder/sock0")
        # Add bridge to ovs
        host_ovs.add_ovs_bridge("br1-ovs", "system")

        # Plug representor port
        host_ovs.create_ovs_vif_port("br1-ovs", "enp2s0f1_0")
    except Exception as e:
        print(e)

if __name__ == "__main__":
    main()
