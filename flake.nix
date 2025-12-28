{
  inputs = {
    # This is pointing to an unstable release.
    # If you prefer a stable release instead, you can this to the latest number shown here: https://nixos.org/download
    # Use `nix flake update` to update the flake to the latest revision of the chosen release channel.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    inputs@{ self, nixpkgs, ... }:
    rec {
      packages.x86_64-linux = {
        default = nixosConfigurations.nixos.config.system.build.vm;
        digitalOceanImage = nixosConfigurations.digix.config.system.build.digitalOceanImage;
      };

      # NOTE: 'nixos' is the default hostname
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          {
            nixlab = {
              doomemacs-support.enable = true;
              trust-auth.enable = true;
              qemu-support.enable = true;
            };
          }
        ];
      };

      nixosConfigurations.digix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
          ./configuration.nix
          {
            nixlab = {
              trust-auth.enable = true;
              virtualization.k3s.enable = true;
              virtualization.k3s.isServer = true;
            };
          }
        ];
      };
    };
}
