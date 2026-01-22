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

  scripts.deploy.exec = ''
    nixos-rebuild switch --flake .#digitalocean --target-host digix --ask-sudo-password
  '';

  scripts.update.exec = ''
    nix flake update && git commit -am "chore: Update flake.lock" && git push
  '';
}
