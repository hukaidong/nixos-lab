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
              # Current sftpgo treats ports = 0 as disabled,
              # so use localhost and a high port as a workaround.
              # TODO: Switch back to unix socket or port = 0 when this is fixed.
              address = "127.0.0.1";
              port = 10080;
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
          sftpgo-webdav.servers."127.0.0.1:10080" = { };
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
