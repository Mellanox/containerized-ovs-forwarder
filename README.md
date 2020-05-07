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
$ MLNX_OFED_VERSION=50218 /bin/bash build.sh
```
Now the ovs-docker image created successfully

## Build OVS container
Once the image is ready, you can create the container by running container_create script:  
Pass the required arguements to container_create,

```--port <port_number> OVS manager port default to 6000```

```--pci_args <pci_address> <vfs_range> A pci address of dpdk interface and range of vfs```

In case of bonding or you have more than one NIC for dpdk, reuse the --pci_args

```--pmd-cpu-mask <mask> A core bitmask that sets which cores are used by OVS-DPDK for datapath packet processing```  

```
$ MLNX_OFED_VERSION=50218 /bin/bash container_create.sh --pci_args 0000:02:00.0 0-3 --port 6000 
```
Now the ovs-forwarder created successfully

## Start OVS container
Then start the contaier by running:
```
$ docker start ovs-forwarder:$MLNX_OFED_VERSION
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
