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
    claude-code
  ];

  services.openssh.enable = true;

  system.stateVersion = "25.11";

  # QEMU-specific module configuration
  nixlab = {
    auth.trusted.enable = true;
    desktop.xfce.enable = true;
    editors.doom-emacs.enable = true;
    services.sftpgo = {
      enable = true;
      hostNames = {
        webdav = "dav.hukaidong.local";
        httpd = "httpd.hukaidong.local";
      };
    };
    services.nginx.enable = true;
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "sftpgo"
    ];
}
