# Development shell for this repository.
#
# Defined here rather than in flake.nix so the flake stays a thin entry point
# that only maps configurations to outputs.
#
# Enter with `nix develop`, or automatically through direnv (see .envrc).
{ pkgs }:

let
  # Helper scripts, replacing the former devenv.nix `scripts.deploy`/`scripts.update`.
  deploy = pkgs.writeShellScriptBin "deploy" ''
    nh os switch .#digitalocean --target-host digix --elevation-strategy passwordless
  '';

  # Evaluates every check (each host included) before committing, so a lock
  # bump that breaks a host is never pushed.
  update = pkgs.writeShellScriptBin "update" ''
    nix flake update && nix flake check --no-build && git commit -am "chore: Update flake.lock" && git push
  '';

  # Wrapping vulnix in a buildEnv prevents mkShell from overriding the Nix
  # already provided by the host, matching how devenv installed it.
  vulnixEnv = pkgs.buildEnv {
    name = "vulnix";
    paths = [ pkgs.vulnix ];
    pathsToLink = [ "/bin" ];
  };
in
pkgs.mkShell {
  packages = with pkgs; [
    age
    cachix
    deadnix
    nh
    nixd
    statix
    vulnixEnv
    deploy
    update
  ];

  shellHook = ''
    echo "NixOS infrastructure shell ready — 'update' refreshes flake.lock, 'deploy' rebuilds digitalocean over SSH via nh."
  '';
}
