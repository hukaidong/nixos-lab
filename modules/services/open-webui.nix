{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.nixlab.services.open-webui;
in
{
  options.nixlab.services.open-webui = {
    enable = mkEnableOption "Open-WebUI, a web interface for LLM chat.";
    hostName = mkOption {
      type = types.str;
      default = "chat.hukaidong.com";
      description = "The host name for the Open-WebUI service.";
    };
    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Which port the Open-WebUI server listens to.";
    };
    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Extra environment variables for Open-WebUI.";
    };
    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file for passing secrets to the service.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.open-webui = {
        enable = true;
        host = "127.0.0.1";
        port = cfg.port;
        environment = {
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
        } // cfg.environment;
        environmentFile = cfg.environmentFile;
      };
    })

    (mkIf (cfg.enable && config.nixlab.services.nginx.enable) {
      services.nginx = {
        enable = true;

        upstreams = {
          open-webui.servers."127.0.0.1:${toString cfg.port}" = { };
        };

        virtualHosts = {
          "${cfg.hostName}" = {
            locations."/" = {
              proxyPass = "http://open-webui";
              extraConfig = ''
                proxy_http_version 1.1;
                proxy_set_header   Upgrade $http_upgrade;
                proxy_set_header   Connection "upgrade";

                proxy_set_header   Host $host;
                proxy_set_header   X-Real-IP $remote_addr;
                proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header   X-Forwarded-Proto $scheme;
                proxy_set_header   X-Forwarded-Scheme $scheme;

                chunked_transfer_encoding off;
                proxy_buffering off;
                proxy_cache off;
                proxy_request_buffering off;
                client_max_body_size 0;

                proxy_connect_timeout 3600s;
                proxy_send_timeout 3600s;
                proxy_read_timeout 3600s;
              '';
            };
          };
        };
      };

      nixlab.services.nginx.protectedDomains = [ cfg.hostName ];
    })
  ];
}
