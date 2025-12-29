# Hardware configuration for QEMU VM
{ lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Use bridged networking via virbr0 for direct network access
  # Requires host to have virtualisation.libvirtd.enable = true
  # Note: helper= points to SUID wrapper, not QEMU's bundled non-SUID helper
  virtualisation.qemu.options = [
    "-netdev bridge,id=net0,br=virbr0,helper=/run/wrappers/bin/qemu-bridge-helper"
    "-device virtio-net-pci,netdev=net0"
  ];
}
