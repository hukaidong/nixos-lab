{
  description = "NixOS VM builds and cloud infrastructure";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmt = treefmt-nix.lib.evalModule pkgs ./utils/treefmt.nix;
    in
    {
      nixosConfigurations = import ./hosts inputs;

      packages.${system} = {
        default = self.nixosConfigurations.qemu.config.system.build.vm;
        digitalOceanImage = self.nixosConfigurations.digitalocean.config.system.build.digitalOceanImage;
      };

      checks.${system} = import ./tests { inherit self pkgs treefmt; };

      devShells.${system}.default = import ./utils/shell.nix { inherit pkgs; };

      # `nix fmt`: nixfmt, deadnix and statix over every Nix file
      formatter.${system} = treefmt.config.build.wrapper;
    };
}
