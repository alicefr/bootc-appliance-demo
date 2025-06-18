#!/bin/bash

VMNAME=bootc-vm
BOOTC_IMAGE=quay.io/centos-bootc/centos-bootc:stream9
VOL_IMAGE=localhost:vm-layer
OUTPUT_DIR=$(pwd)/output
CONFIG_DIR=$(pwd)/config
CONT_STORAGE=$HOME/.local/share/containers/storage
LOG=$(pwd)/log
SOCK_DIR=$(pwd)/podman
CID=3
VMPORT=1234
PODMAN_SOCK=/var/run/podman/podman-vm.sock
PODMAN_CONN=bootc-vm
OUTPUT=/usr/lib/bootc/output/output.qcow2
set -xe

mkdir -p $OUTPUT_DIR
mkdir -p $LOG
mkdir -p $SOCK_DIR

qemu-img create -f qcow2 $OUTPUT_DIR/output.qcow2 10G

podman build -t libvirt .

# Build layer on top of a bootc image with the setup of the bootc installation. This layer will be only used for
# creating the installation VM but it won't be present in the output disk since we use the original image
podman build -t $VOL_IMAGE --build-arg BASE_IMAGE=$BOOTC_IMAGE -f Containerfile.vmlayer .

podman rm -f libvirt || true 
podman run -td --name libvirt \
	--mount type=image,source=$VOL_IMAGE,destination=/bootc-data,rw=true \
	--network=host \
	--pid=host \
	--ipc=host \
	-e HOME=/home/qemu \
	--security-opt label=disable \
	-v /dev/kvm:/dev/kvm \
	-v /dev/vhost-net:/dev/vhost-net \
	-v /dev/vhost-vsock:/dev/vhost-vsock \
	-v /dev/vsock:/dev/vsock \
	-v $OUTPUT_DIR:/usr/lib/bootc/output \
	-v $CONFIG_DIR:/usr/lib/bootc/config \
	-v $CONT_STORAGE:/usr/lib/bootc/container_storage \
	-v $LOG:/var/run/console \
	-v $SOCK_DIR:/var/run/podman \
	libvirt /libvirtd.sh

podman exec -ti libvirt /install_vm.sh


# Proxy vsock connection
podman exec -td libvirt socat UNIX-LISTEN:$PODMAN_SOCK,reuseaddr,fork VSOCK-CONNECT:3:$VMPORT
podman exec -ti libvirt chmod 0777 $PODMAN_SOCK

podman system connection add $PODMAN_CONN unix://$(pwd)/podman/podman-vm.sock

while ! podman -c $PODMAN_CONN info ; do 
	sleep 1
done

podman -c $PODMAN_CONN run --rm --privileged --pid=host \
	-v /var/lib/containers:/var/lib/containers \
	-v /usr/lib/bootc/container_storage:/var/lib/containers/storage \
	-v /dev:/dev \
	--security-opt label=type:unconfined_t \
	-v /usr/lib/bootc/output:/output \
	-v /usr/lib/bootc/config:/config \
	$BOOTC_IMAGE \
	bootc install to-disk /dev/disk/by-id/virtio-output --wipe

podman exec -ti libvirt virsh destroy $VMNAME  && virsh undefine $VMNAME
podman exec -ti libvirt chmod 0755 $OUTPUT
