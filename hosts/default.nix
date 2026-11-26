# Every machine this flake builds. A host directory holds that machine's
# settings and the profiles it uses; the platform module comes from nixpkgs.
{ nixpkgs, sops-nix, ... }:
let
  mkHost =
    platform: host:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/${platform}"
        sops-nix.nixosModules.sops
        host
      ];
    };
in
{
  # Local QEMU development VM
  qemu = mkHost "virtualisation/qemu-vm.nix" ./qemu;

  # Digital Ocean cloud image
  digitalocean = mkHost "virtualisation/digital-ocean-image.nix" ./digitalocean;
}
