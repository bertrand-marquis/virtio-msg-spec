# PoC v1: 2026-04-23

v1 only contains the transport and bridge to test using loopback on the
same host.
The implementation is compatible with Oasis proposal v1.

## Content:

 - Linux
   - virtio message transport
   - virtio message bridge
   - virtio message dma helper
   - virtio message loopback
 - Qemu
   - virtio message bridge
   - virtio message bridge parent
   - User and devel docs for the bridge
