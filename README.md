# Containerized-ovs-forwarder
This repository builds a container image for ovs forwarder.
Also it implement two ovs modules:
- The containerovsdb which connect to ovs container and create bridges and vdpa ports.
- The ovsdb which connect to ovs on the host  

The ovs modules were taken from [openstack/os-vif](https://github.com/openstack/os-vif/).

## Build ovs-forwarder container image

Go to build directory
```
$ cd build/
```
Specify the MLNX_OFED_VERSION and run the build command
```
$ MLNX_OFED_VERSION=52220 /bin/bash build.sh
```
Now the ovs-docker image created successfully

## Build OVS container
Once the image is ready, you can create the container by running container_create script:  
Pass the required arguements to container_create,

```--port <port_number> OVS manager port default to 6000```

```--pci-args <pci_address> <vfs_range> A pci address of dpdk interface and range of vfs in format pf0vf[range]```

In case of bonding, reuse the --pci-args for the second pf, but make sure to use the pci address of the pf0 and vfs range in format pf1vf[range]  
**Note**: We can't use this new syntax on non vf-lag case with pf1 as a dpdk interface 

```--pmd-cpu-mask <mask> A core bitmask that sets which cores are used by OVS-DPDK for datapath packet processing```  

```
$ MLNX_OFED_VERSION=52220 /bin/bash container_create.sh --pci-args 0000:02:00.0 pf0vf[0-3] --port 6000
```  
In case of bonding it should be like this  
```
$ MLNX_OFED_VERSION=52220 /bin/bash container_create.sh --pci-args 0000:02:00.0 pf0vf[0-3] --pci-args 0000:02:00.0 pf1vf[0-3] --port 6000
```  

Now the ovs-forwarder created successfully

## Prerequisites  
Make sure you have installed all of the following prerequisites on the host machine:  
  - With connection tracking:  
    - openvswitch-2.13 and above  
    - MLNX_OFED_LINUX-5.2-2.2.0.0 and above  
    - kernel-5.7 and above with connection tracking modules  

  - Without connection tracking:  
    - Openvswitch, openvswitch-2.12 and above  
    - MLNX_OFED_LINUX-5.2-2.2.0.0 and above  

## Supported Hardware
Containerized OVS Forwarder has been validated to work with the following Mellanox hardware:
- ConnectX-5 family adapters => min FW is 16.28.2006
- ConnectX-6Dx family adapters => min FW is 22.28.2006


## Enable UCTX
Make sure that you have UCTX_EN enabled in FW configuration  
  ```
  $ mlxconfig -d mlx5_0 q UCTX_EN
  ```
if it's disabled run this command and reboot the server  
  ```
  $ mlxconfig -d mlx5_0 s UCTX_EN=1
  ```

## Enable switchdev mode
  Before starting ovs container, make sure to have vfs in switchdev mode and the vfs are binded
- None vf-lag case
  - Create vfs on mlnx port  
    ```$ echo 4 > /sys/class/net/p4p1/device/sriov_numvfs```  
  - Unbind vfs for mlnx port  
    ```$ for i in `lspci -D | grep nox | grep Virt| awk '{print $1}'`; do echo  $i > /sys/bus/pci/drivers/mlx5_core/unbind; done```  
  - Move mlnx port to switchdev mode  
    ```$ /usr/sbin/devlink dev eswitch set pci/0000:03:00.0 mode switchdev```  
  - Bind vfs for mlnx port  
    ```$ for i in `lspci -D | grep nox | grep Virt| awk '{print $1}'`; do echo  $i > /sys/bus/pci/drivers/mlx5_core/bind; done```  

- Vf-lag case
  - Create vfs on both mlnx ports   
    ``` echo 4 > /sys/class/net/p4p1/device/sriov_numvfs```  
    ``` echo 4 > /sys/class/net/p4p2/device/sriov_numvfs```  
  - Unbind vfs for both mlnx ports  
    ```$ for i in `lspci -D | grep nox | grep Virt| awk '{print $1}'`; do echo  $i > /sys/bus/pci/drivers/mlx5_core/unbind; done```  
  - Move mlnx ports to switchdev mode  
    ```/usr/sbin/devlink dev eswitch set pci/0000:03:00.0 mode switchdev```  
    ```/usr/sbin/devlink dev eswitch set pci/0000:03:00.1 mode switchdev```  
  - Plug mlnx ports to bond interface  
  - Bind vfs for both mlnx ports  
    ```for i in `lspci -D | grep nox | grep Virt| awk '{print $1}'`; do echo  $i > /sys/bus/pci/drivers/mlx5_core/bind; done```

## Start OVS container
Then start the contaier by running:
```
$ docker start ovs-forwarder:$MLNX_OFED_VERSION
```

## Enable debugging inside OVS container  
To enable debug in ovs inside the container, you can run the following command inside the container:  
  ```
  $ ovs-appctl vlog/set dpdk::DBG
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

