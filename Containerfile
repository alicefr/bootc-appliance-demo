FROM quay.io/fedora/fedora:42

RUN dnf install -y \
	libvirt-client \
	libvirt-daemon \
	libvirt-daemon-driver-qemu \
	libvirt-daemon-driver-storage-core \
	qemu-kvm \
	socat \
	virt-install \
	virtiofsd \
	&& dnf clean all

RUN mkdir -p /home/qemu && chown -R qemu:qemu /home/qemu
RUN mkdir -p /etc/libvirt

COPY ./libvirtd.sh /libvirtd.sh
COPY ./qemu.conf /etc/libvirt/qemu.conf
COPY ./virtqemud.conf /etc/libvirt/virtqemud.conf
COPY ./install_vm.sh /install_vm.sh
COPY podman-vsock-proxy.service /podman-vsock-proxy.service
COPY ./virtiofsd-wrapper /usr/local/bin/virtiofsd-wrapper
COPY mount-vfsd-targets.service /mount-vfsd-targets.service
COPY mount-vfsd-targets.sh /mount-vfsd-targets.sh
ENTRYPOINT ["/libvirtd.sh"]
