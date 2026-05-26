This is a virtio message PoC using Linux and QEMU.

# Disclaimer

ChatGPT was heavily used to generate this PoC. Even if I did some review and
modifications on the generated code, it is still at PoC status and not ready
yet for upstreaming.

# QEMU patches and compilation

QEMU patches in the qemu sub-directory must be applied on QEMU master.
Current development was done on top of Edgar patches that can be found
in https://github.com/edgarigl/qemu.git and I started from his branch
edgar/virtio-msg-rfc that I rebased on top of QEMU master
(hash 314ff2e07ddc6163554077d68aed5d76a50b8e3d).

The QEMU series currently contains 30 patches:
- patches 0001 to 0004 are Edgar's original virtio-msg/AMP PCI base
- patches 0005 to 0023 update QEMU memory, virtio and virtio-msg behavior for
  the current protocol and bridge requirements
- patches 0024 to 0028 add the Linux bridge backend, the transport parent, the
  imported Linux bridge UAPI header and the documentation
- patches 0029 and 0030 add build support for the minimal aarch64
  vmsg-bridge-min profile

I am using the following command to compile QEMU:
```
make docker-image-debian-arm64-cross && \
  docker run --rm -it \
    -u "$(id -u):$(id -g)" \
    -v "$PWD":/src \
    -w /src \
    qemu/debian-arm64-cross \
    bash -lc '
      set -e
      mkdir -p build-aarch64-static
      cd build-aarch64-static
      ../configure \
        --cross-prefix=aarch64-linux-gnu- \
        --target-list=aarch64-softmmu \
        --static \
        --disable-pie \
        --without-default-features \
        --without-default-devices \
        --with-devices-aarch64=vmsg-bridge-min \
        --disable-docs
      make -j"$(nproc)"
```

# Linux patches and compilation

Linux patches in the linux sub-directory are introducing:
- virtio message transport
- a virtio message userspace bridge interface
- virtio message DMA helpers for driver and device roles
- a shared bus queue helper
- a virtio message loopback transport and bridge provider for local validation
- FF-A bus support:
  - common FF-A bus/protocol code
  - indirect, FIFO and direct transfer support
  - FF-A driver-role binding
  - FF-A device-role binding

The FF-A bus support is included in this PoC patch drop, but it currently
depends on Arm FF-A kernel changes that are not included in this directory.
Those Arm FF-A patches will be provided in a later PoC update. Until then, the
FF-A bus driver will not compile at this stage.

Patches have been tested and apply on Linux v6.19.3 tree.

For the loopback-based QEMU validation path, you must activate the following
symbols in your Linux configuration:
```
CONFIG_VIRTIO_MSG_TRANSPORT=y
CONFIG_VIRTIO_MSG_BRIDGE=y
CONFIG_VIRTIO_MSG_LOOPBACK=y
```

# Reproduce the POC

The following reproduces the loopback-based QEMU bridge validation path. It
does not validate the FF-A bus bindings.

From Linux with a root filesystem containing the modified QEMU, run the
following command to start QEMU with a block and entropy device:

- Create a fake disk file:
```
dd if=/dev/zero of=/tmp/disk.img bs=1M count=32
```

- Run QEMU:
```
qemu-system-aarch64 -M virt -m 128 -nographic -nodefaults \
    -device virtio-msg-linux-bridge-transport,id=vmsgw0,endpoint=loopback \
    -object rng-random,id=rng0,filename=/dev/urandom \
    -device virtio-rng-device,bus=/vmsgw0/bus/virtio-msg/bus1/virtio-msg-dev,rng=rng0 \
    -drive if=none,id=vdisk0,file=/tmp/disk.img,format=raw \
    -device virtio-blk-device,id=vblk0,bus=/vmsgw0/bus/virtio-msg/bus2/virtio-msg-dev,drive=vdisk0
```

You can confirm that works with the logs that should appear from kernel:
```
virtio-msg-bridge: client attached: bus='loopback' endpoint=2 vmm_max_msg_size=128
virtio-msg-loopback: loopback slot start: dev=1
 (null): provider attached: bus='loopback' dev=1
virtio-msg-loopback: loopback slot start: dev=2
 (null): provider attached: bus='loopback' dev=2
 (null): device register: bus='loopback' dev=1
 (null): device register: bus='loopback' dev=2
virtio_blk virtio1: 1/0/0 default/read/poll queues
virtio_blk virtio1: [vda] 65536 512-byte logical blocks (33.6 MB/32.0 MiB)
```

and /sys/bus/virtio/devices should show 2 devices.

# Validation tests

```
mkfs.ext2 /dev/vda
mkdir /mnt
mount /dev/vda /mnt
dd if=/dev/hwrng of=/mnt/test1 bs=256 count=256
dd if=/dev/urandom of=/mnt/test2 bs=1024 count=4096
cp /mnt/test2 /mnt/test3
sync
md5sum /mnt/test*
umount /mnt
mount /dev/vda /mnt
md5sum /mnt/test*
```
