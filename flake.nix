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
      packages.x86_64-linux.default = nixosConfigurations.nixos.config.system.build.vm;

      # NOTE: 'nixos' is the default hostname
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        modules = [ ./configuration.nix ];
      };
    };
}
