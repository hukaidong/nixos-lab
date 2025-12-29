{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.nixlab.auth;
in
{
  options.nixlab.auth = {
    enable = mkEnableOption "Secure authentication for cloud VMs";
  };

  config = mkIf cfg.enable {
    users.users.kaidong = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
      };
    };

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };

    security.sudo.wheelNeedsPassword = true;
  };
}
