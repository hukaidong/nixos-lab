# SOPS secrets management
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.nixlab.secrets;
in
{
  options.nixlab.secrets = {
    enable = mkEnableOption "SOPS secrets management";

    cloudflare = {
      enable = mkEnableOption "Cloudflare origin certificates";
    };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets/cfcert.yaml;
      age.keyFile = "/etc/sops/age/key.txt";

      secrets = mkIf cfg.cloudflare.enable {
        "cloudflare.oc.pem" = {
          sopsFile = ../../secrets/cfcert.yaml;
          key = "cloudflare_oc_pem";
        };
        "cloudflare.oc.cert" = {
          sopsFile = ../../secrets/cfcert.yaml;
          key = "cloudflare_oc_cert";
        };
      };
    };
  };
}
