#!/bin/bash 

DISK=./output/output.qcow2
NAME=test-output

virsh destroy $NAME && virsh undefine $NAME
virt-install \
    --name  $NAME \
    --cpu host-model \
    --vcpus 4 \
    --memory 4096 \
    --import \
	 --disk path=$DISK,format=qcow2 \
	 --graphics vnc,listen=0.0.0.0 \
    --console pty,target_type=serial \
    --noautoconsole \
    --os-variant generic
