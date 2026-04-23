This a virtio message POC using linux and qemu

# Disclaimer

ChatGPT was heavily used to generate this PoC. Even if i did some review and
modifications on the generated code, it is still at PoC status and not ready
yet for upstreaming.

# Qemu patches and compilation

qemu patches in qemu sub-directory must be applied in qemu master status.
Current development was done on top of Edgar patches that can be found
in https://github.com/edgarigl/qemu.git and i started from his branch
edgar/virtio-msg-rfc that i rebased on top of master from qemu
(hash 314ff2e07ddc6163554077d68aed5d76a50b8e3d).

First 4 patches are Edgar original patches and then there are modifications
in standard qemu code and Edgar virtio-msg code and then a bridge
implementation with a transport parent.
At the end of the serie there are 2 patches to create a minimal qemu
and to fix a qemu compilation error with that configuration.

I am using the following command to compile qemu:
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

# Linux patches and compilation

linux patches in linux sub-directory are introducing:
- virtio message transport
- a virtio message bridge interface
- a virtio message dma helper
- a virtio message loopback for local validation without VM

Patches have been tested and apply on linux v6.19.3 tree.

You must activate the following symbols in your linux configuration:
CONFIG_VIRTIO_MSG_TRANSPORT=y
CONFIG_VIRTIO_MSG_BRIDGE=y
CONFIG_VIRTIO_MSG_LOOPBACK=y

# Reproduce the POC

From linux with a root filesystem containing the modified Qemu, run the
following command to start Qemu with a block and entropy device:

- Create a fake disk file:
dd if=/dev/zero of=/tmp/disk.img bs=1M count=32

- Run qemu:
qemu-system-aarch64 -M virt -m 128 -nographic -nodefaults \
    -device virtio-msg-linux-bridge-transport,id=vmsgw0,endpoint=loopback \
    -object rng-random,id=rng0,filename=/dev/urandom \
    -device virtio-rng-device,bus=/vmsgw0/bus/virtio-msg/bus1/virtio-msg-dev,rng=rng0 \
    -drive if=none,id=vdisk0,file=/tmp/disk.img,format=raw \
    -device virtio-blk-device,id=vblk0,bus=/vmsgw0/bus/virtio-msg/bus2/virtio-msg-dev,drive=vdisk0

You can confirm that works with the logs that should appear from kernel:
virtio-msg-bridge: client attached: bus='loopback' endpoint=2 vmm_max_msg_size=128
virtio-msg-loopback: loopback slot start: dev=1
 (null): provider attached: bus='loopback' dev=1
virtio-msg-loopback: loopback slot start: dev=2
 (null): provider attached: bus='loopback' dev=2
 (null): device register: bus='loopback' dev=1
 (null): device register: bus='loopback' dev=2
virtio_blk virtio1: 1/0/0 default/read/poll queues
virtio_blk virtio1: [vda] 65536 512-byte logical blocks (33.6 MB/32.0 MiB)

and /sys/bus/virtio/devices should show 2 devices.

# Validation tests

mkfs.ext2 /dev/vda
mkdir /mnt
mount /dev/vda /mnt
dd if=/dev/hwrng of=/mnt/test1 bs=256 count=4096 (can take some time)
cp /mnt/test1 /mnt/test2
sync
md5sum /mnt/test*
umount /mnt
mount /dev/vda /mnt
md5sum /mnt/test*

