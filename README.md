# Containerized-ovs-forwarder
This repository implements a solution for supporting vdpa with ovs-kernel:
  - Builds a container image for ovs forwarder.
  - Implement two ovs modules:
    - The containerovsdb which connect to ovs container and create bridges and vdpa ports.
    - The ovsdb which connect to ovs on the host.  
  - Provide required openstack patches for train and ussuri releases.  

The ovs modules were taken from [openstack/os-vif](https://github.com/openstack/os-vif/).  

Also it explains how to configure the setup and the VDPA port inside the container.

## Prerequisites
Make sure you have installed all of the following prerequisites on the host machine:
  - With connection tracking:
    - openvswitch-2.14 and above
    - MLNX_OFED_LINUX-5.2-2.2.0.0 and above
    - kernel-5.7 and above with connection tracking modules

  - Without connection tracking:
    - Openvswitch, openvswitch-2.12 and above
    - MLNX_OFED_LINUX-5.2-2.2.0.0 and above

  - Align the host OFED version with the container OFED version

## Supported Hardware
Containerized OVS Forwarder has been validated to work with the following Mellanox hardware:
- ConnectX-5 family adapters => min FW is 16.29.2002
- ConnectX-6Dx family adapters => min FW is 22.29.2002

## Enable UCTX
Make sure that you have UCTX_EN enabled in FW configuration  
  ```
  $ mlxconfig -d mlx5_0 q UCTX_EN
  ```
if it's disabled run this command and reboot the server  
  ```
  $ mlxconfig -d mlx5_0 s UCTX_EN=1
  ```

## Disable SELinux  
Make sure that you have selinux in permissive mode or disabled in your host machine  
  ```  
  $ getenforce  
  ```  
If it's not in Permissive mode or disabled set it using this command:  
  ```  
  $ setenforce Permissive  
  ```  
And to make it's permanent, open the file `/etc/selinux/config` and change the option SELINUX to disabled or permissive  

## Openstack integration  
For openstack integration go to [openstack guidelines](openstack/README.md).  

## Enable switchdev mode
Before starting ovs container, make sure to have vfs in switchdev mode and the vfs are binded

- None vf-lag case:
  - Create vfs on mlnx port
    ```
    echo 4 > /sys/class/net/p4p1/device/sriov_numvfs
    ```
  - Unbind vfs for mlnx port
    ```
    for i in `lspci -D | grep nox | grep Virt| awk '{print $1}'`; do echo $i > /sys/bus/pci/drivers/mlx5_core/unbind; done
    ```
  - Move mlnx port to switchdev mode
    ```
    /usr/sbin/devlink dev eswitch set pci/0000:03:00.0 mode switchdev
    ```
  - Bind vfs for mlnx port
    ```
    $ for i in `lspci -D | grep nox | grep Virt| awk '{print $1}'`; do echo $i > /sys/bus/pci/drivers/mlx5_core/bind; done
    ```

- vf-lag case:
  - Create vfs on mlnx port
    ```
    echo 4 > /sys/class/net/p4p1/device/sriov_numvfs
    echo 4 > /sys/class/net/p4p2/device/sriov_numvfs
    ```
  - Unbind vfs for mlnx port
    ```
    for i in `lspci -D | grep nox | grep Virt| awk '{print $1}'`; do echo $i > /sys/bus/pci/drivers/mlx5_core/unbind; done
    ```
  - Move mlnx port to switchdev mode
    ```
    /usr/sbin/devlink dev eswitch set pci/0000:03:00.0 mode switchdev
    /usr/sbin/devlink dev eswitch set pci/0000:03:00.1 mode switchdev
    ```
  - Create linux bonding interface
    ```
    vim /etc/sysconfig/network-scripts/ifcfg-bond1
        NAME=bond1
        DEVICE=bond1
        BONDING_MASTER=yes
        TYPE=Bond
        IPADDR=<Desired IP>
        NETMASK=<Desired netmask>
        IPV6ADDR=<Desired IPV6>
        ONBOOT=no
        BOOTPROTO=none
        BONDING_OPTS=<Bonding options>
        NM_CONTROLLED=no

    vim /etc/sysconfig/network-scripts/ifcfg-slave1
        NAME=<Desired name>
        DEVICE=<PF1>
        TYPE=Ethernet
        BOOTPROTO=none
        ONBOOT=no
        MASTER=bond1
        SLAVE=yes
        NM_CONTROLLED=no

    vim /etc/sysconfig/network-scripts/ifcfg-slave2
        NAME=<Desired name>
        DEVICE=<PF2>
        TYPE=Ethernet
        BOOTPROTO=none
        ONBOOT=no
        MASTER=bond1
        SLAVE=yes
        NM_CONTROLLED=no
    ```
  - Bring up bond interface
    ```
    ifup bond1
    ```
  - Bind vfs for mlnx port
    ```
    $ for i in `lspci -D | grep nox | grep Virt| awk '{print $1}'`; do echo $i > /sys/bus/pci/drivers/mlx5_core/bind; done
    ```

## Build ovs-forwarder container image (not needed incase you pull docker image from docker hub)  

Go to build directory
```
$ cd build/
$ /bin/bash build.sh
```
Now the ovs-docker image created successfully

## Pull docker image from docker hub 

  - Install and start docker: https://docs.docker.com/engine/install/centos/
  - Container from docker.io/mellanox/ovs-forwarder can be used:
    Check at the following link  https://hub.docker.com/r/mellanox/ovs-forwarder/tags
    ```
    docker pull mellanox/ovs-forwarder:52220
    ```
  - check image pulled successfully
    ```
    docker images
    ```
  - clone containerized-ovs-forwarder:
    ```
    git clone https://github.com/Mellanox/containerized-ovs-forwarder
    ```
  - change directory to containerized-ovs-forwarder:
    ```
    cd containerized-ovs-forwarder/
    mkdir -p /forwarder/var/run/openvswitch/
    ```
  - update container_create.sh file with the correct docker image name instead of "ovs-forwarder":
    ```
    #!/bin/bash
    # Create ovs container
    docker container create \
    --privileged \
    --network host \
    --name ovs_forwarder_container \
    --restart unless-stopped \
    -v /dev/hugepages:/dev/hugepages \
    -v /var/lib/vhost_sockets/:/var/lib/vhost_sockets/ \
    docker.io/mellanox/ovs-forwarder:$MLNX_OFED_VERSION\
    $@
    ```

## Build OVS container
Once the image is ready, you can create the container by running container_create script:  
Pass the required arguements to container_create,

```
   --port <port_number> OVS manager port default to 6000
```

```
   --pci-args <pci_address> <vfs_range> A pci address of dpdk interface and range of vfs in format pf0vf[range]
```

In case of bonding, reuse the --pci-args for the second pf, but make sure to use the pci address of the pf0 and vfs range in format pf1vf[range]  
**Note**: We can't use this new syntax on non vf-lag case with pf1 as a dpdk interface 

```
   --pmd-cpu-mask <mask> A core bitmask that sets which cores are used by OVS-DPDK for datapath packet processing
```

```
$ MLNX_OFED_VERSION=52220 /bin/bash container_create.sh --pci-args 0000:02:00.0 pf0vf[0-3] --port 6000
```  
In case of bonding it should be like this  
```
$ MLNX_OFED_VERSION=52220 /bin/bash container_create.sh --pci-args 0000:02:00.0 pf0vf[0-3] --pci-args 0000:02:00.0 pf1vf[0-3] --port 6000
```  

Now the ovs-forwarder created successfully

## Enable debugging inside OVS container  
To enable debug in ovs inside the container, you can run the following command inside the container:  
  ```
  $ ovs-appctl vlog/set dpdk::DBG
  ```  
## MTU / jumbo frame configuration
  - Verify kernel on VM is 4.14+
    ```
    cat /etc/redhat-release
    ```
  - Set MTU on both physical interfaces in the host:
    ```
    ifconfig ens4f0 mtu 9216
    ```
  - Send large size packet and verify it's sent and received correctly:
    ```
    tcpdump -i ens4f0 -nev icmp &
    ping 11.100.126.1 -s 9188 -M do -c 1
    ```
  - Enable host_mtu in xml add the following values to xml 
    ```
    <domain type='kvm' id='21' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
    <qemu:commandline>
    <qemu:arg value='-set'/>
    <qemu:arg value='device.net1.host_mtu=9216'/>
    </qemu:commandline>
    ```
    * net1 is the alias name of the interface (it can be found by virsh dumpxml command)
  - Add mtu_request=9216 option to the OvS ports inside the container and restart the OvS:
    ```
    ovs-vsctl set port vdpa0 mtu_request=9216
    /usr/share/openvswitch/scripts/ovs-ctl restart
    ```
  - Start VM, configure MTU on VM:
    ```
    ifconfig eth0 11.100.124.2/16 up
    ifconfig eth0 mtu 9216
    ping 11.100.126.1 -s 9188 -M do -c1
    ```

## VM XML changes:
  - Add page-per-vq for performance improvements
    ```
    <qemu:arg value='-set'/>
    <qemu:arg value='device.net0.page-per-vq=on'/>
    ```
  - Add driver queues under interface configuration for balancing traffic between PFs in vf lag mode:
    ```
    <driver queues='8'/>
    ```

  - Add memoryBacking section to reduce memory consumed by ovs-vswitchd thread inside the docker: 
    ```
    <memoryBacking>
    <hugepages>
      <page size='1048576' unit='KiB'/>
    </hugepages>
    </memoryBacking>
    ```

## Use ovs_modules
You can use the python/example.py script in order to use ovs modules  
The script creates netdev bridge and vdpa port on the container,
and also create a bridge and plug representor port on the host  
Before using the ovs modules make sure that the requirements in requirements.txt are installed  
```
$ cd python
$ python example.py
```

