# Flake checks. Besides the VM tests, every host's system is a check, so a
# host that no longer evaluates or builds fails `nix flake check`.
# `nix flake check --no-build` only evaluates, which takes about a minute.
{
  self,
  pkgs,
  treefmt,
}:
{
  # Boots the hub and two spokes: `nix build .#checks.x86_64-linux.wireguard -L`
  wireguard = pkgs.testers.runNixOSTest ./wireguard.nix;

  # Fails when `nix fmt` would change a file or a lint is left that it cannot
  # fix (utils/treefmt.nix). Run `nix fmt` and commit the result.
  formatting = treefmt.config.build.check self;
}
// pkgs.lib.mapAttrs' (
  name: host: pkgs.lib.nameValuePair "nixos-${name}" host.config.system.build.toplevel
) self.nixosConfigurations
