# Create disk image
```bash
$ podman build --device /dev/kvm -t vm-disk .
$ podman export $(podman create vm-disk /) |tar xvf -
```
# Launch VM
```bash
$ install_vm.sh
```

# Execute command inside the VM
```bash
./execute-cmd.bash podman images
REPOSITORY                         TAG         IMAGE ID      CREATED       SIZE
quay.io/centos-bootc/centos-bootc  stream9     176c3c9010ac  20 hours ago  1.67 GB
```
