from ovs_module.ovsdb import ovsdb_lib


def main():

    # Connect to OVS
    ovs = ovsdb_lib.BaseOVS()

    # Add bridge to ovs
    ovs.add_ovs_bridge("br0-ovs", "netdev")

    # Create vdpa port
    ovs.create_vdpa_port("br0-ovs",
                         "vdpa0",
                         "/var/run/virtio-forwarder/sock0",
                         "0000:02:00.1", "0000:02:02.2",
                         "0")


def cleanup():

    # Delete ovs port
    ovs.delete_ovs_vif_port("br0-ovs", "vdpa0")

    # Delete ovs bridge
    ovs.delete_ovs_bridge("br0-ovs")

if __name__ == "__main__":
    main()
