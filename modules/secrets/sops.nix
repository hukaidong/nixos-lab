# SOPS secrets management
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;

  cfg = config.nixlab.secrets;
in
{
  options.nixlab.secrets = {
    enable = mkEnableOption "SOPS secrets management";

    cloudflare = {
      enable = mkEnableOption "Cloudflare origin certificates";
    };

    wireguard = {
      enable = mkEnableOption ''
        the WireGuard hub's private key, `wireguard_private_key` in
        secrets/secret.yaml. Point
        {option}`nixlab.networking.wireguard.privateKeyFile` at
        `config.sops.secrets."wireguard.key".path` to use it
      '';
    };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets/cfcert.yaml;
      age.keyFile = "/etc/sops/age/key.txt";

      secrets = mkMerge [
        (mkIf cfg.cloudflare.enable {
          "cloudflare.oc.pem" = {
            sopsFile = ../../secrets/cfcert.yaml;
            key = "cloudflare_oc_pem";
          };
          "cloudflare.oc.cert" = {
            sopsFile = ../../secrets/cfcert.yaml;
            key = "cloudflare_oc_cert";
          };
        })

        # Owned by root with mode 0400, which is all the interface's service
        # needs. Restart it so a changed key is loaded.
        (mkIf cfg.wireguard.enable {
          "wireguard.key" = {
            sopsFile = ../../secrets/secret.yaml;
            key = "wireguard_private_key";
            restartUnits = [ "wireguard-${config.nixlab.networking.wireguard.interface}.service" ];
          };
        })
      ];
    };
  };
}
