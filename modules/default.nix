# Every nixlab option module, imported into every host. Each one declares
# options under `nixlab.` and changes nothing until a host enables it, which is
# what makes importing all of them safe. Settings that apply as soon as they
# are imported are profiles, in ../profiles, and hosts import those by name.
#
# A module's helpers sit in a directory named after it (networking/wireguard/
# next to networking/wireguard.nix). They are not modules, so they are left out.
{ lib, ... }:
let
  isModule =
    path:
    lib.hasSuffix ".nix" (toString path)
    && path != ./default.nix
    && !builtins.pathExists (dirOf path + ".nix");
in
{
  _class = "nixos";

  imports = lib.filter isModule (lib.filesystem.listFilesRecursive ./.);
}
