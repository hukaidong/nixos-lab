{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.nixlab.services.sftpgo;
in
{
  options.nixlab.services.sftpgo = {
    enable = mkEnableOption "SFTPGo is a fully featured SFTP server with optional FTP, WebDAV, and HTTP(S) support.";
    hostNames = mkOption {
      type = types.attrsOf types.str;
      default = {
        webdav = "dav.hukaidong.com";
        httpd = "storage.hukaidong.com";
      };
      description = "The host names for the SFTPGo service.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "sftpgo" ];

      services.sftpgo = {
        enable = true;
        settings = {
          common.defender = {
            enable = true;
            ban_time = 30;
            threshold = 15;
          };

          data_provider = {
            driver = "sqlite";
            name = "/var/lib/sftpgo/sftpgo.db";
          };

          webdavd.bindings = [
            {
              address = "/run/sftpgo/webdav.sock";
              port = 0;
            }
          ];

          httpd.bindings = [
            {
              address = "/run/sftpgo/httpd.sock";
              port = 0;
            }
          ];

          sftpd.bindings = [ { port = 0; } ];
          ftpd.bindings = [ { port = 0; } ];
        };
      };
    })

    (mkIf (cfg.enable && config.nixlab.services.nginx.enable) {
      users.users.nginx.extraGroups = [ "sftpgo" ];

      services.nginx = {
        enable = true;

        upstreams = {
          sftpgo-webdav.servers."unix:/run/sftpgo/webdav.sock" = { };
          sftpgo-httpd.servers."unix:/run/sftpgo/httpd.sock" = { };
        };

        virtualHosts = {
          "${cfg.hostNames.webdav}" = {
            locations."/" = {
              proxyPass = "http://sftpgo-webdav";
              extraConfig = ''
                proxy_set_header   Host $host;
                proxy_set_header   X-Real-IP $remote_addr;
                proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header   X-Forwarded-Proto $scheme;

                proxy_buffering off;
                proxy_request_buffering off;
                client_max_body_size 0;

                proxy_connect_timeout 300s;
                proxy_send_timeout 300s;
                proxy_read_timeout 300s;
              '';
            };
          };
          "${cfg.hostNames.httpd}" = {
            locations."/" = {
              proxyPass = "http://sftpgo-httpd";
              extraConfig = ''
                proxy_set_header   Host $host;
                proxy_set_header   X-Real-IP $remote_addr;
                proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header   X-Forwarded-Proto $scheme;

                proxy_buffering off;
                proxy_request_buffering off;
                client_max_body_size 0;

                proxy_connect_timeout 300s;
                proxy_send_timeout 300s;
                proxy_read_timeout 300s;
              '';
            };
          };
        };
      };

      systemd.services.sftpgo.serviceConfig = {
        RuntimeDirectory = "sftpgo";
        RuntimeDirectoryMode = "0755";
      };

      nixlab.services.nginx.protectedDomains = attrValues cfg.hostNames;
    })
  ];
}
