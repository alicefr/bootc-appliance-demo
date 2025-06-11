#!/bin/bash

function cleanup() {
	virsh undefine test && virsh destroy test
}

NAME=bootc-build
DISK=$(pwd)/disk.img
# Directory where the bootc artifacts will be stored
OUTPUT_DIR=$(pwd)/output
OUTPUT=$OUTPUT_DIR/output.qcow2

# Container storage
STORAGE_DIR=$HOME/.local/share/containers

# Directory where to store the configuration for bootc
CONFIG_DIR=$(pwd)/config
BOOTC_IMAGE=quay.io/centos-bootc/centos-bootc:stream9

CID=3
VMPORT=1234
PODMAN_SOCK=/tmp/podman-vm.sock
PODMAN_CONN=bootc-vm
cleanup

set -xe

mkdir -p $STORAGE_DIR
mkdir -p $OUTPUT_DIR

podman pull $BOOTC_IMAGE

# The output image where we install the OS with bootc
rm -f $OUTPUT
qemu-img create -f qcow2 $OUTPUT 10G

# Extract the root disk
podman build --device /dev/kvm -t vm-disk .
podman export $(podman create vm-disk /) |tar xvf -


virsh destroy $NAME && virsh undefine $NAME
/usr/bin/virt-install \
  --import \
  --virt-type kvm \
  --cpu host-model \
  --name $NAME \
  --memory 2048 \
  --vcpus 2 \
  --disk path=$DISK,format=qcow2,target=vda,bus=virtio \
  --disk path=$OUTPUT,format=qcow2,target=vdb,serial=output,bus=virtio \
  --filesystem source=$STORAGE_DIR,target=storage,driver.type=virtiofs \
  --filesystem source=$CONFIG_DIR,target=config,driver.type=virtiofs \
  --filesystem source=$OUTPUT_DIR,target=output,driver.type=virtiofs \
  --memorybacking=source.type=memfd,access.mode=shared \
  --graphics vnc,listen=0.0.0.0 \
  --console pty,target_type=serial \
  --noautoconsole \
  --os-variant generic \
  --vsock cid.address=$CID

# This can be removed once podman understand vsock
rm -f $PODMAN_SOCK
socat UNIX-LISTEN:$PODMAN_SOCK,fork VSOCK-CONNECT:3:$VMPORT &

podman system connection add $PODMAN_CONN unix://$PODMAN_SOCK

# Wait until the VM boot
while ! podman -c $PODMAN_CONN info &> /dev/null ; do sleep 1; done

podman -c $PODMAN_CONN run --rm --privileged --pid=host \
	-v /var/lib/containers:/var/lib/containers \
	-v /dev:/dev \
	--security-opt label=type:unconfined_t \
	-v /usr/lib/bootc/output:/output \
	-v /usr/lib/bootc/config:/config \
	$BOOTC_IMAGE \
	bootc install to-disk /dev/disk/by-id/virtio-output

