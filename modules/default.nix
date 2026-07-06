# All nixlab modules, auto-imported recursively
{ lib, ... }:
let
  nixFiles = lib.filesystem.listFilesRecursive ./.;
  moduleFiles = builtins.filter (
    path: lib.hasSuffix ".nix" (toString path) && (toString path) != (toString ./default.nix)
  ) nixFiles;
in
{
  imports = moduleFiles;
}
