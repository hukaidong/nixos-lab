# Digital Ocean droplet configuration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules
  ];

  # Base system packages
  environment.systemPackages = with pkgs; [
    bash
    git
    kitty
    vim
    comma
    uutils-coreutils-noprefix
  ];

  services.openssh.enable = true;

  system.stateVersion = "25.11";

  # Digital Ocean-specific module configuration
  nixlab = {
    auth.secure.enable = true;

    services.grocy.enable = true;
    services.sftpgo.enable = true;

    services.nginx = {
      enable = true;
      enableCfSSL = true;
    };
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "sftpgo"
    ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-public-keys = [
      "digix-build:MUfI7WSJIrQb+kNaTnVw1mYMeWBvoi0Ovb9eWPc+enM="
    ];
  };
}
