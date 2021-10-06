# Openstack ovs-kernel with OVN

## Description

This repo has serveral patches that should be applied to the following openstack compenents to support virtio forwarder in OVN deployments:  
- Neutron  
    Adding the required changes in controller nodes (neutron_api service/container) to support creating virtio forwarder ports  
- Nova  
    Adding the required changes in Compute nodes (nova_compute service/container) to convert the nova.network.model to proper os_vif object  
- Os-vif  
    Adding the required changes in Compute nodes (nova_compute service/container) to plug in the representor port to ovs and vdpa port to containerized ovs  

## configure vhostuser socket directory  

```  
$ mkdir -p /var/lib/vhost_sockets/  
$ chmod 775 /var/lib/vhost_sockets/  
$ chown qemu:hugetlbfs /var/lib/vhost_sockets/  
```  

## preparing ovs-forwarder container  
On all compute nodes do the following to prepare the ovs-forwarder container

### Pulling ovs forwarder image

```
$ podman pull mellanox/ovs-forwarder:52220
```  

### Creating ovs forwarder container
``` 
$ mkdir -p /forwarder/var/run/openvswitch/ 
```
```
$ podman container create \
    --privileged \
    --network host \
    --name ovs_forwarder_container \
    --restart always \
    -v /dev/hugepages:/dev/hugepages \
    -v /var/lib/vhost_sockets/:/var/lib/vhost_sockets/ \
    -v /forwarder/var/run/openvswitch/:/var/run/openvswitch/ \
    docker.io/mellanox/ovs-forwarder:52220 \
    --pci-args 0000:02:00.0 pf0vf[0-3]
```  
in case the vf-lag pass the pci of the first pf and vfs range for the second pf, like this:
```  
podman container create \
    --privileged \
    --network host \
    --name ovs_forwarder_container \
    --restart always \
    -v /dev/hugepages:/dev/hugepages \
    -v /var/lib/vhost_sockets/:/var/lib/vhost_sockets/ \
    -v /forwarder/var/run/openvswitch/:/var/run/openvswitch/ \
    docker.io/mellanox/ovs-forwarder:52220 \
    --pci-args0000:02:00.0 pf0vf[0-3] --pci-args 0000:02:00.0 pf1vf[0-3]
```  

### creating ovs forwarder container service
The ovs_forwarder_container_service_create.sh creates ovs forwarder container service which starts the ovs forwarder container after the reboot  
```  
$ /bin/bash ovs_forwarder_container_service_create.sh
```  

## Apply openstack patches

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
    
- nova.patch should be applied to  
    - /usr/lib/python3.6/site-packages/nova/network/os_vif_util.py
    - /usr/lib/python3.6/site-packages/nova/virt/libvirt/config.py
    - /usr/lib/python3.6/site-packages/nova/virt/libvirt/driver.py
    ```
    $ cd /usr/lib/python3.6/site-packages/nova
    $ patch -p2 < nova.patch
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
On each compute node configure the following files:

-  We need to configure the group to be hugetlbfs
   ```
   Edit /etc/libvirt/qemu.conf config with adding  
   group = "hugetlbfs"  
   ```

-   We need to reserved_huge_pages option to reserve huge pages for the forwarder  
   ```
   Edit /var/lib/config-data/puppet-generated/nova_libvirt/etc/nova/nova.conf  
   reserved_huge_pages=node:0,size:1GB,count:8  
   reserved_huge_pages=node:1,size:1GB,count:8  
   ```

After that restart the nova, lbvirt  and neutron services/contianers  

## Creating an instance:

### Create image  
```  
$ openstack image create --public --file rhel_8_inbox_driver.qcow2  --disk-format qcow2 --container-format bare rhel_8_inbox  
$ openstack image set --property hw_vif_multiqueue_enabled=true rhel_8_inbox  
```  
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
$ openstack flavor create --ram 2048 --vcpus 4 --property hw:cpu_policy=dedicated --property hw:mem_page_size=1GB --public dpdk.1g
```
Note:
Please make sure that you have configured hugepages in the host before you create the instance  
You can do it with the following steps:  
  - Edit the file /etc/default/grub and add "intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=8" to the existing GRUB_CMDLINE_LINUX line
  - Run command ``` $ grub2-mkconfig -o /boot/grub2/grub.cfg```
  - Reboot the host

### Create instance
```
$ openstack server create  --flavor dpdk.1g  --image mellanox --nic port-id=$virtio_port --availability-zone nova:overcloud-computesriov-0.localdomain vm
```
