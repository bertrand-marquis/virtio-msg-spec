# PoC v2: 2026-05-26

v2 contains transport, bridge, loopback and FF-A bus device and driver
implementation. It is compatible with the v2 OASIS proposal and FF-A bus ALP2
(not released yet) specification.

The FF-A bus support depends on Arm FF-A kernel patches that are not included
in this PoC update yet. Those patches will be provided in a later PoC update.
Until then, the FF-A bus driver will not compile at this stage.

## New Content compared to v1

  - Linux
    - virtio message bridge DMA device helper
    - shared virtio message bus queue helper
    - virtio message FF-A bus common code
    - FF-A indirect transfer support
    - FF-A FIFO transfer support
    - FF-A direct transfer support for the driver role
    - virtio message FF-A driver-role binding
    - virtio message FF-A device-role binding
  - QEMU
    - direct-map-only DMA address space support for bridge mappings
    - retryable disconnected-peer handling and must-deliver sends
    - transport capability latching
    - transport revision 1 message layout synchronization
    - malformed request filtering and explicit completion status handling
    - bounded bus, config and event messages
    - vqueue state flag support
    - empty GET_SHM response support
    - Linux bridge backend and transport parent
    - Linux bridge system and developer documentation
    - minimal aarch64 vmsg-bridge-min build profile

## Main changes compared to v1

  - Transport configuration handling
    - v1 used a shadow config cache so that virtio config callbacks could be
      answered without always sending a transport request. That cache has been
      removed.
    - GET_CONFIG now fetches authoritative config bytes from the peer on
      demand. Large reads are split into message-size-limited chunks, and the
      whole read is retried when chunks observe different config generations.
    - SET_CONFIG now sends the written bytes directly to the peer. The response
      is only used to confirm the accepted range and returned generation; echoed
      config bytes are ignored.
    - EVENT_CONFIG no longer updates cached config bytes. The event validates
      the reported range, updates the last observed generation and device
      status, and notifies the virtio core. The next driver config read gets
      the bytes through GET_CONFIG.
    - get_config and set_config from non-sleepable context are now refused
      instead of being hidden behind cached data. Non-sleepable get_config
      zero-fills the caller buffer and marks the transport fatal; non-sleepable
      set_config marks the transport fatal.
    - strict config generation is not negotiated in this revision, so SET_CONFIG
      sends generation 0 and QEMU masks strict-generation support for the Linux
      bridge path.
  - Linux transport and provider simplification
    - request/response paths are now explicitly sleepable.
    - event delivery remains a fast provider path and providers can use the
      shared bus queue helper when they need to hand work from non-sleepable
      context to a sleepable submit context.
    - global queue handling has been reworked around the shared queue helper.
    - dead code from the v1 prototype was removed.
  - Bridge interface rework
    - DMA and bus messages now use the same bridge queue, so QEMU does not need
      to wait on both an ioctl path and a ring path for runtime bridge traffic.
    - DMA add/del now carries a keep hint so pool shares are not unmapped unless
      Linux asks for it. The FF-A protocol also carries this hint, reducing MMU
      and message pressure for pool-based mappings.
  - QEMU transport behavior
    - transport capabilities are latched so child devices see stable revision,
      maximum message size, feature masks and DMA address space.
    - valid responses and generated events use must-deliver send paths instead
      of best-effort delivery.
    - malformed peer requests are dropped locally, while missing devices and
      local completion failures are reported through explicit transport status.
    - config accesses and config events are bounded by the active transport
      message size.

# PoC v1: 2026-04-23

v1 only contains the transport and bridge to test using loopback on the
same host.
The implementation is compatible with OASIS proposal v1.

## Content:

 - Linux
   - virtio message transport
   - virtio message bridge
   - virtio message DMA helper
   - virtio message loopback
 - QEMU
   - virtio message bridge
   - virtio message bridge parent
   - User and devel docs for the bridge
