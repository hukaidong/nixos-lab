# The address book of nixlab.networking.wireguard: what a `hosts.<name>` entry
# holds, and the names it gets in the DNS zone.
{ lib }:
let
  inherit (lib) mkOption types;

  ipv4 = types.strMatching "([0-9]{1,3}\\.){3}[0-9]{1,3}";
in
{
  # The `hosts.<name>` submodule.
  host =
    { name, ... }:
    {
      options = {
        address = mkOption {
          type = ipv4;
          example = "10.77.0.2";
          description = "Static tunnel address of ${name}, inside {option}`subnet`.";
        };

        publicKey = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            WireGuard public key of ${name}. A spoke without one is left out
            of the tunnel (with a warning), which lets a new machine be listed
            before its key exists. Ignored for the hub's own entry, where it
            only records the key the spokes need.
          '';
        };

        aliases = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "grafana" ];
          description = "Extra names under {option}`domain` that resolve to ${name}.";
        };
      };
    };

  # Every DNS name of a host under `domain`: <name>.<domain> first (the one
  # PTR answers with), then its aliases.
  dnsNames =
    domain: name: host:
    map (label: "${label}.${domain}") ([ name ] ++ host.aliases);
}
