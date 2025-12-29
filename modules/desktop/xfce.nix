# XFCE desktop environment for QEMU VMs
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.nixlab.desktop.xfce;
in
{
  options.nixlab.desktop.xfce = {
    enable = mkEnableOption "XFCE desktop environment";
  };

  config = mkIf cfg.enable {
    services.xserver.enable = true;
    services.xserver.desktopManager.xfce.enable = true;

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
