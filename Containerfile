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
COPY ./virtiofsd-wrapper /usr/local/bin/virtiofsd-wrapper
ENTRYPOINT ["/libvirtd.sh"]
