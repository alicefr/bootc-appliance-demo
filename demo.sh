#!/bin/bash

function cleanup() {
	virsh undefine test && virsh destroy test
}

DISK=$(pwd)/disk.img
OUTPUT_DIR=$(pwd)/output
OUTPUT=$OUTPUT_DIR/output.qcow2

STORAGE_DIR=$HOME/.local/share/containers/storage

CONFIG_DIR=$(pwd)/config
BOOTC_IMAGE=quay.io/centos-bootc/centos-bootc:stream9

cleanup
set -e

mkdir -p $STORAGE_DIR
mkdir -p $OUTPUT_DIR

podman pull $BOOTC_IMAGE
# The output image where we install the OS with bootc
rm -f $OUTPUT
qemu-img create -f qcow2 $OUTPUT 10G

# Extract the root diks
podman build --device /dev/kvm -t vm-disk .
podman export $(podman create vm-disk /) |tar xvf -

/usr/bin/virt-install \
  --import \
  --virt-type kvm \
  --cpu host-model \
  --name test \
  --memory 2048 \
  --vcpus 2 \
  --disk path=$DISK,format=qcow2,target=vda \
  --disk path=$OUTPUT,format=qcow2,target=vdb,serial=output \
  --filesystem source=$STORAGE_DIR,target=storage,driver.type=virtiofs \
  --filesystem source=$CONFIG_DIR,target=config,driver.type=virtiofs \
  --filesystem source=$OUTPUT_DIR,target=output,driver.type=virtiofs \
  --memorybacking=source.type=memfd,access.mode=shared \
  --graphics vnc,listen=0.0.0.0 \
  --console pty,target_type=serial \
  --noautoconsole \
  --os-variant fedora41 \
  --channel type=unix,mode=bind,target_type=virtio,name=org.qemu.guest_agent.0  

./execute-cmd podman run --rm --privileged --pid=host \
	-v /usr/lib/bootc/storage:/var/lib/containers \
	-v /dev:/dev \
	--security-opt label=type:unconfined_t \
	-v /usr/lib/bootc/output:/output \
	-v /usr/lib/bootc/config:/config \
	$BOOTC_IMAGE \
	bootc install to-disk /dev/disk/by-id/virtio-output

cleanup
