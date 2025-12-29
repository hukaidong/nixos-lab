# Trusted network authentication - password-based for local development
{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.nixlab.auth.trusted;
in
{
  options.nixlab.auth.trusted = {
    enable = mkEnableOption "Trusted network authentication (password-based)";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.nixlab.auth.secure.enable;
        message = "Cannot enable both trusted and secure auth modules simultaneously";
      }
    ];

    users.users.kaidong = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "kaidong";
      shell = pkgs.zsh;
    };

    # Trusted network - allow passwordless sudo
    security.sudo.extraRules = [
      {
        users = [ "kaidong" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
