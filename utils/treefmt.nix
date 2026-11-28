# Formatting and lint rules for every Nix file, as a treefmt-nix module.
# `nix fmt` applies them, and the `formatting` check fails when `nix fmt`
# would change a file or a lint is left that it cannot fix.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  projectRootFile = "flake.nix";

  # In this order, since removing an unused binding or applying a statix fix
  # can leave code that nixfmt would lay out differently.
  programs = {
    deadnix = {
      enable = true;
      priority = 1;
    };
    statix = {
      enable = true;
      priority = 2;
    };
    nixfmt = {
      enable = true;
      priority = 3;
    };
  };

  settings = {
    # treefmt sees a lint only through the change its fix makes, so a lint
    # statix cannot fix (repeated keys, for one) would pass. Check each file
    # after fixing it, so any warning left fails `nix fmt` and the check.
    formatter.statix.command = lib.mkForce (
      pkgs.writeShellScriptBin "statix-fix-check" ''
        status=0
        for file in "$@"; do
          ${lib.getExe config.programs.statix.package} fix "$file"
          ${lib.getExe config.programs.statix.package} check "$file" || status=1
        done
        exit $status
      ''
    );

    # Files no formatter claims (secrets, the README) are expected.
    on-unmatched = "info";
  };
}
