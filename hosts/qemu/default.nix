# QEMU VM host configuration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  # Base system packages
  environment.systemPackages = with pkgs; [
    bash
    git
    kitty
    uutils-coreutils-noprefix
  ];

  services.openssh.enable = true;

  system.stateVersion = "25.11";

  # QEMU-specific module configuration
  nixlab = {
    auth.trusted.enable = true;
    desktop.xfce.enable = true;
    editors.doom-emacs.enable = true;
  };
}
