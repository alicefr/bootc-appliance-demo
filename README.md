# Create a bootc image running rootless podman

The `demo.sh` script builds a VM image with an environment for running podman remote using VSOCK and some predefined 
mount points to facilitate the bootc builds.

Run the demo:
```bash
./demo.sh
```

Verify the output image with a local VM:
```bash
./test-output.
virsh console test-output
```
