# Containerized-ovs-forwarder
This repository explains how to build a container image for ovs forwarder.
Also it implement an ovs module that will connect to the container from
the host and create bridges and vdpa ports.
The ovs module was taken from [openstack/os-vif](https://github.com/openstack/os-vif/).

## Build ovs-forwarder container image

Go to ovs_container directory
```
# cd ovs_container/
```
Open the Dockerfile and configure the ARGS to match yours
In case of bonding or you have more than one NIC for dpdk edit the
ARGS variable to be something like this
ENV ARGS "--pci_args 0000:02:00.0 0-3 --pci_args 0000:02:00.1 0-7 --port 5678"

You also may need to change MLNX_OFED_VERSION
After that run the build command
```
# docker build -t ovs-docker .
```
The ovs-docker is the image name

## Build OVS container
Once the image is ready, so you can create the container by running:
```
# ./container_create.sh
```
## Start OVS container
Then start the contaier by running:
```
# docker start ovs_container
```

## Use ovs_module
Now in order to connect to the ovs from the host, you need to import
ovsdb_lib and then use its functions to manage bridges and ovs ports
ovs_module_example.py is an example how o connect and create a brdige and vdpa port

