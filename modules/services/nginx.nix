{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.nixlab.services.nginx;

  # Generate virtual host config for each protected domain
  protectedVhosts = listToAttrs (
    map (domain: {
      name = domain;
      value = {
        forceSSL = true;
        sslCertificate = config.sops.secrets."cloudflare.oc.cert".path;
        sslCertificateKey = config.sops.secrets."cloudflare.oc.pem".path;
      };
    }) cfg.protectedDomains
  );
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
    services.nginx = {
      enable = true;
      recommendedTlsSettings = cfg.enableCfSSL;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = false;

      virtualHosts = mkIf cfg.enableCfSSL protectedVhosts;
    };

    # Enable SOPS secrets for Cloudflare certificates
    nixlab.secrets = mkIf cfg.enableCfSSL {
      enable = true;
      cloudflare.enable = true;
    };

    # Ensure nginx can read the secrets
    sops.secrets = mkIf cfg.enableCfSSL {
      "cloudflare.oc.cert".owner = config.services.nginx.user;
      "cloudflare.oc.pem".owner = config.services.nginx.user;
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
