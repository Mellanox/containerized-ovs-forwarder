# Openstack ovs-kernel with OVN

## Description

This repo has serveral patches that should be applied to the following openstack compenents to support virtio forwarder in OVN deployments:  
- Neutron  
    Adding the required changes in controller nodes (neutron_api service/container) to support creating virtio forwarder ports  
- Nova  
    Adding the required changes in Compute nodes (nova_compute service/container) to convert the nova.network.model to proper os_vif object  
- Os-vif  
    Adding the required changes in Compute nodes (nova_compute service/container) to plug in the representor port to ovs and vdpa port to containerized ovs  


## Apply patches

After preparing the setup and creating the ovs-forwarder container, apply the following patches for the relevant OpenStack release:  
Note: if the setup is containerized, please make sure to apply patches inside the related container

- networking-ovn.patch should be applied to  
    /usr/lib/python3.6/site-packages/neutron/plugins/ml2/drivers/ovn/mech_driver/mech_driver.py
    Note in train release it will applied to /usr/lib/python3.6/site-packages/neutron/networking_ovn/ml2/mech_driver.py
    ```
    $ cd /usr/lib/python3.6/site-packages/neutron
    $ patch -p1 < networking-ovn.patch
    ```
    Note in train release it will applied to /usr/lib/python3.6/site-packages/neutron/networking_ovn/ml2/mech_driver.py
    
- nova_os_vif_util.patch should be applied to  
    /usr/lib/python3.6/site-packages/nova/network/os_vif_util.py
    ```
    $ cd /usr/lib/python3.6/site-packages/nova
    $ patch -p2 < nova_os_vif_util.patch
    ```

- os-vif.patch shoule be applied to the following files  
    - /usr/lib/python3.6/site-packages/vif_plug_ovs/constants.py
    - /usr/lib/python3.6/site-packages/vif_plug_ovs/linux_net.py
    - /usr/lib/python3.6/site-packages/vif_plug_ovs/ovs.py
  
  But before of that you have to copy python/ovs_module directory to /usr/lib/python3.6/site-packages/

    ```
    $ cp -a python/ovs_module /usr/lib/python3.6/site-packages/
    $ cd /usr/lib/python3.6/site-packages/vif_plug_ovs
    $ patch < os-vif.patch
    ```
Edit /etc/libvirt/qemu.conf config with adding
group = "hugetlbfs"

After that restart the nova, lbvirt  and neutron services/contianers


## Creating ovs forwarder container service
The ovs_forwarder_container_service_create.sh creates ovs forwarder container service which starts the ovs forwarder container after the reboot  
```  
$ /bin/bash ovs_forwarder_container_service_create.sh
```  

## Creating an instance:

### Create network
```
$ private_network_id=`openstack network create private --provider-network-type geneve --share | grep ' id ' | awk '{print $4}'`
```
### Create subnet
```
$ openstack subnet create private_subnet --dhcp --network private --subnet-range 11.11.11.0/24
```
### Create port
```
$ virtio_port=`openstack port create virtio_port --vnic-type=virtio-forwarder --network $private_network_id | grep ' id ' | awk '{print $4}'`
```
### Create flavor
```
$ openstack flavor create --ram 2048 --vcpus 4 --property dpdk=true --property hw:cpu_policy=dedicated --property hw:mem_page_size=1GB --property hw:emulator_threads_policy=isolate  --public dpdk.1g
```
Note:
Please make sure that you have configured hugepages in the host before you create the instance  
You can do it with the following steps:  
  - Edit the file /etc/default/grub and add "intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=8 hugepagesz=2M hugepages=1024" to the existing GRUB_CMDLINE_LINUX line
  - Run command ``` $ grub2-mkconfig -o /boot/grub2/grub.cfg```
  - Reboot the host

### Create instance
```
$ openstack server create  --flavor dpdk.1g  --image mellanox --nic port-id=$virtio_port --availability-zone nova:overcloud-computesriov-0.localdomain vm
```
