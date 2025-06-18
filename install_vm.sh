#!/bin/bash -x

VMNAME=bootc-vm
CMDLINE="console=ttyS0 rootfstype=virtiofs root=root rw init=/sbin/init"
CID=3
VMPORT=1234
PODMAN_SOCK=/var/run/podman/podman-vm.sock
VFSD="driver.type=virtiofs,binary.path=/usr/local/bin/virtiofsd-wrapper"
OUTPUT=/usr/lib/bootc/output/output.qcow2
# Detect boot artifacts from the bootc image
dir=/bootc-data
kernel=$(ls $dir/usr/lib/modules/*/vmlinuz)
initrd=$(ls $dir/usr/lib/modules/*/initramfs.img)

virsh destroy $VMNAME && virsh undefine $VMNAME

set -e

virt-install \
	--connect qemu:///session \
    --name $VMNAME \
	 --os-variant generic \
    --cpu host-model \
    --vcpus 2 \
    --memory 2048 \
    --import \
	 --boot kernel=${kernel},initrd=${initrd},cmdline="$CMDLINE" \
	 --filesystem source=/bootc-data,target=root,$VFSD \
	 --filesystem source=/usr/lib/bootc/output,target=output,$VFSD \
	 --filesystem source=/usr/lib/bootc/config,target=config,$VFSD \
	 --filesystem source=/usr/lib/bootc/container_storage,target=storage,$VFSD \
    --disk path=$OUTPUT,format=qcow2,target=vdb,serial=output,bus=virtio \
    --memorybacking=source.type=memfd,access.mode=shared \
	 --graphics vnc,listen=0.0.0.0,port=5959 \
	 --console unix,path=/var/run/console/console.sock,mode=bind \
    --os-variant generic \
    --vsock cid.address=$CID \
	 --noautoconsole

chmod 0777 /var/run/console/console.sock
