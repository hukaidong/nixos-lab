# Secure authentication - SSH key-based for cloud/remote VMs
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.nixlab.auth.secure;
in
{
  options.nixlab.auth.secure = {
    enable = mkEnableOption "Secure authentication (SSH key-based)";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.nixlab.auth.trusted.enable;
        message = "Cannot enable both trusted and secure auth modules simultaneously";
      }
    ];

    users.users.kaidong = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = [ ../../secrets/authorized_keys ];
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
