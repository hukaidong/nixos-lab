# Flake checks. Besides the VM tests, every host's system is a check, so a
# host that no longer evaluates or builds fails `nix flake check`.
# `nix flake check --no-build` only evaluates, which takes about a minute.
{ self, pkgs }:
{
  # Boots the hub and two spokes: `nix build .#checks.x86_64-linux.wireguard -L`
  wireguard = pkgs.testers.runNixOSTest ./wireguard.nix;
}
// pkgs.lib.mapAttrs' (
  name: host: pkgs.lib.nameValuePair "nixos-${name}" host.config.system.build.toplevel
) self.nixosConfigurations
