#!/bin/bash 

virt-install \
    --name fedora-bootc \
    --cpu host-model \
    --vcpus 4 \
    --memory 4096 \
    --import --disk ./output.qcow2,format=qcow2 \
	 --graphics vnc,listen=0.0.0.0 \
    --console pty,target_type=serial \
    --noautoconsole \
    --os-variant fedora-eln
