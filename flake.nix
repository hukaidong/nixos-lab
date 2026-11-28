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
    {
      nixosConfigurations = import ./hosts inputs;

      packages.${system} = {
        default = self.nixosConfigurations.qemu.config.system.build.vm;
        digitalOceanImage = self.nixosConfigurations.digitalocean.config.system.build.digitalOceanImage;
      };

      checks.${system} = import ./tests { inherit self pkgs; };

      devShells.${system}.default = import ./utils/shell.nix { inherit pkgs; };
    };
}
