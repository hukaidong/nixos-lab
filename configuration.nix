# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Non-configurable modules
    ./hardware-configuration.nix
    ./customized-zsh.nix

    # Configure-controlled modules
    ./doomemacs-support.nix
    ./qemu-support.nix
    ./k3s.nix
    ./trust-auth.nix
  ];

  environment.systemPackages = with pkgs; [
    bash # for script expect bash or sh
    git
    kitty # terminal emulator, also kitty-terminfo for ssh support
    uutils-coreutils-noprefix # Rusted coreutils, no prefix
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  system.stateVersion = "25.11";

}
