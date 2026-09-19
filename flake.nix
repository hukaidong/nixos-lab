{
  description = "NixOS VM builds and cloud infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    sops-nix.url = "github:Mic92/sops-nix";

    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    rec {
      devShells.${system}.default = import ./util/shell.nix { inherit pkgs; };

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
            inputs.sops-nix.nixosModules.sops
            ./hosts/qemu
          ];
        };

        # Digital Ocean cloud image
        digitalocean = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
            inputs.sops-nix.nixosModules.sops
            ./hosts/digitalocean
          ];
        };

        digitalocean-minimum = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
            inputs.sops-nix.nixosModules.sops
            ./hosts/digitalocean/minimum
          ];
        };
      };
    };
}
