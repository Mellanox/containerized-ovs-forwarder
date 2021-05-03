# Libvirt
In this repo we have the libvirt patch file that add page_per_vq flag to the driver element of virtio devices which is important for vdpa with vhost-user performance  
We have two versions of patch here, the original patch based on master code and backported one to libvirt 6.6  

## Install source rpm  
```  
$ wget https://cbs.centos.org/kojifiles/packages/libvirt/6.6.0/13.el8/src/libvirt-6.6.0-13.el8.src.rpm  
$ rpm -ivh libvirt-6.6.0-13.el8.src.rpm  
```  

## Append the patch to spec file  
```  
$ cp ./libvirt-6.6.0/0001-Add-page_per_vq-flag-to-the-driver-element-of-virtio.patch /root/rpmbuild/SOURCES/  
```  
Then you need to apeend the patch to `Source1: symlinks` in `/root/rpmbuild/SPECS/libvirt.spec` file, similar to this line  
`Patch137: 0001-Add-page_per_vq-flag-to-the-driver-element-of-virtio.patch`  
  

## Build libvirt rpms  
```  
$ rpmbuild -bb /root/rpmbuild/SPECS/libvirt.spec  
```  
RPMS are created under `/root/rpmbuild/RPMS/x86_64/`
