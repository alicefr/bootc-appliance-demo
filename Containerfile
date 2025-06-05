FROM quay.io/fedora/fedora:42 as builder

ENV URL https://download.fedoraproject.org/pub/fedora/linux/releases/42/Cloud/x86_64/images
ENV IMAGE Fedora-Cloud-Base-Generic-42-1.1.x86_64.qcow2
ENV CHECKSUM Fedora-Cloud-42-1.1-x86_64-CHECKSUM
ENV LIBGUESTFS_BACKEND direct

RUN dnf install -y curl libguestfs guestfs-tools curl

RUN curl -L -O $URL/$IMAGE \
 	&& curl -L -O $URL/$CHECKSUM \
   && curl -O https://fedoraproject.org/fedora.gpg \
	&& gpgv --keyring ./fedora.gpg $CHECKSUM \
	&& sha256sum --ignore-missing -c $CHECKSUM \
	&& mv $IMAGE /disk.img

# Configuration of the guest image
RUN virt-customize -a /disk.img --install qemu-guest-agent,podman \
	--root-password password:test \
	--run-command "sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config" \
	--run-command "mkdir -p /usr/lib/bootc/config" \
	--run-command "echo \"config /usr/lib/bootc/config virtiofs rw,relatime,nofail 0 0\" >> /etc/fstab" \
	--run-command "mkdir -p /usr/lib/bootc/storage" \
	--run-command "echo \"storage /usr/lib/bootc/storage virtiofs rw,relatime,nofail 0 0\" >> /etc/fstab" \
	--run-command "mkdir -p /usr/lib/bootc/output" \
	--run-command "echo \"output /var/lib/containers virtiofs rw,relatime,nofail 0 0\" >> /etc/fstab" \
	--run-command "dnf clean all -y"  \
	&& virt-sparsify --in-place /disk.img

FROM scratch
COPY --from=builder /disk.img /disk.img
