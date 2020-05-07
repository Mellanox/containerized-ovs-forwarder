from ovs_module.containerovsdb import api as ovsdb_api


class BaseOVS(object):

    def __init__(self, connection='tcp:127.0.0.1:6000', timeout=120):
        self.timeout = timeout
        self.connection = connection
        self.ovsdb = ovsdb_api.get_instance(self)

    def add_ovs_bridge(self, bridge, datapath_type):
        """Create OVS bridge
        :param bridge: bridge name.
        :param datapath_type: datapath type of the bridge.
        """
        return self.ovsdb.add_br(bridge, may_exist=True,
                                 datapath_type=datapath_type).execute()

    def create_ovs_vif_port(self, bridge, dev, interface_type=None,
                            pf_pci=None, vf_pci=None, vf_num=None,
                            vdpa_socket_path=None, tag=None):

        """Create OVS port
        :param bridge: bridge name to create the port on.
        :param dev: port name.
        :param interface_type: OVS interface type.
        :param pf_pci: PCI address of PF for dpdk representor port.
        :param vf_pci: PCI address of VF for dpdk representor port.
        :param vf_num: VF number of PF for dpdk representor port.
        :param vdpa_socket_path:path to socket file.
        :param tag: OVS interface tag.
        """

        col_values = []
        if interface_type == "dpdkvdpa":
            col_values.append(('type', 'dpdkvdpa'))
            col_values.append(('options',
                               {'vdpa-socket-path': vdpa_socket_path}))
            col_values.append(('options',
                               {'vdpa-accelerator-devargs': vf_pci}))
            devargs_string = "{PF_PCI},representor=[{VF_NUM}]".format(
                PF_PCI=pf_pci, VF_NUM=vf_num)
            col_values.append(('options',
                               {'dpdk-devargs': devargs_string}))
        with self.ovsdb.transaction() as txn:
            txn.add(self.ovsdb.add_port(bridge, dev))
            if tag:
                txn.add(self.ovsdb.db_set('Port', dev, ('tag', tag)))
            txn.add(self.ovsdb.db_set('Interface', dev, *col_values))

    def delete_ovs_vif_port(self, bridge, dev, delete_netdev=True):
        self.ovsdb.del_port(dev, bridge=bridge, if_exists=True).execute()

    def delete_ovs_bridge(self, bridge):
        return self.ovsdb.del_br(bridge).execute()
