{
  description = "NixOS VM builds and cloud infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    rec {
      packages.x86_64-linux = {
        default = nixosConfigurations.qemu.config.system.build.vm;
        digitalOceanImage = nixosConfigurations.digitalocean.config.system.build.digitalOceanImage;
      };

      nixosConfigurations = {
        # Local QEMU development VM
        qemu = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
            ./hosts/qemu
          ];
        };

        # Digital Ocean cloud image
        digitalocean = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
            ./hosts/digitalocean
          ];
        };
      };
    };
}
