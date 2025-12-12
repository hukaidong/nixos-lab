{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.nixlab.qemu-support;
in
{
  options.nixlab.qemu-support = {
    enable = mkEnableOption "QEMU support";
  };

  config = mkIf cfg.enable {
    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.desktopManager.xfce.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "dvp";
    };

    environment.systemPackages = with pkgs; [
      spice-vdagent
      spice-autorandr
    ];
  };
}
