{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.nixlab.services.grocy;
in
{
  options.nixlab.services.grocy = {
    enable = mkEnableOption "Grocy self-hosted groceries and household management solution";
    hostName = mkOption {
      type = types.str;
      default = "grocy.hukaidong.com";
      description = "The host name for the Grocy service.";
    };
  };

  config = mkIf cfg.enable {
    services.grocy = {
      enable = true;
      hostName = cfg.hostName;
      nginx.enableSSL = false;
    };

    nixlab.services.nginx.protectedDomains = [ cfg.hostName ];

    # Open port 80 (for standalone debugging) if Cloudflare SSL is not enabled, mostly on qemu testing
    networking.firewall.allowedTCPPorts = if !config.nixlab.services.nginx.enable then [ 80 ] else [ ];
  };
}
