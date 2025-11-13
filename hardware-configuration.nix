# This configuration is used for vm only
{ lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
