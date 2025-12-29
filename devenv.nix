{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  languages = {
    nix.enable = true;
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    age
  ];
}
