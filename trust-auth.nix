{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.nixlab.trust-auth;
in
{
  options.nixlab.trust-auth = {
    enable = mkEnableOption "Trust authentication and related settings";
  };

  config = mkIf cfg.enable {
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.kaidong = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      initialPassword = "kaidong";
      shell = pkgs.zsh;
    };

    # The lab is run in a trusted network, so we allow password authentication.
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
