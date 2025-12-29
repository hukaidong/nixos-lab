{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.nixlab.services.nginx;
in
{
  options.nixlab.services.nginx = {
    enable = mkEnableOption "Nginx web server";

    enableCfSSL = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Cloudflare SSL for Nginx.";
    };

    protectedDomains = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of domains to protect with Cloudflare SSL.";
    };
  };

  config = mkIf cfg.enable {
    # TODO: Add Nginx configuration here
  };
}
