# WireGuard hub: a private network with static addresses and a small DNS zone
# between this host and the machines listed in `hosts`.
#
# The topology is hub-and-spoke. The hub has a public address and listens on
# `listenPort`. Every other host dials in (most sit behind NAT) and keeps the
# path open with PersistentKeepalive, so the hub needs only their public keys,
# not their endpoints. Spokes reach each other through the hub.
#
# `hosts` is the address book for the whole network. It drives the peer list
# here, the DNS zone served on the tunnel address, and /etc/hosts on the hub.
# Spokes are configured in their own repositories with this host's public
# key, its endpoint and their own address from this table.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.nixlab.networking.wireguard;
  iface = cfg.interface;

  prefixLength = last (splitString "/" cfg.subnet);
  hub =
    cfg.hosts.${cfg.self}
      or (throw "nixlab.networking.wireguard.self (${cfg.self}) must name an entry in nixlab.networking.wireguard.hosts.");
  spokes = filterAttrs (name: _: name != cfg.self) cfg.hosts;
  withKey = filterAttrs (_: host: host.publicKey != null) spokes;
  withoutKey = attrNames (filterAttrs (_: host: host.publicKey == null) spokes);

  fqdn = name: "${name}.${cfg.domain}";
  # Every DNS name of a host: <name>.<domain> first (the one PTR answers
  # with), then its aliases.
  dnsNames = name: host: [ (fqdn name) ] ++ map fqdn host.aliases;

  addresses = mapAttrsToList (_: host: host.address) cfg.hosts;

  ipv4 = types.strMatching "([0-9]{1,3}\\.){3}[0-9]{1,3}";

  hostOpts =
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
in
{
  options.nixlab.networking.wireguard = {
    enable = mkEnableOption "the WireGuard hub and its private DNS zone";

    interface = mkOption {
      type = types.str;
      default = "wg0";
      description = "Name of the WireGuard interface.";
    };

    listenPort = mkOption {
      type = types.port;
      default = 51820;
      description = ''
        UDP port the hub listens on. It is opened in the NixOS firewall; a
        DigitalOcean Cloud Firewall in front of the droplet must allow it too.
      '';
    };

    subnet = mkOption {
      type = types.str;
      default = "10.77.0.0/24";
      description = "The tunnel network, in CIDR notation. Every host's address is in it.";
    };

    domain = mkOption {
      type = types.str;
      default = "wg.internal";
      description = ''
        DNS zone for the tunnel. Each host gets `<name>.<domain>`. The
        `.internal` top-level domain is reserved for private use and is never
        delegated on the public internet.
      '';
    };

    self = mkOption {
      type = types.str;
      example = "digix";
      description = "Name of this host (the hub) in {option}`hosts`.";
    };

    hosts = mkOption {
      type = types.attrsOf (types.submodule hostOpts);
      default = { };
      description = "Every machine on the tunnel, the hub included, by DNS name.";
    };

    privateKeyFile = mkOption {
      type = types.str;
      default = "/var/lib/wireguard/${iface}.key";
      defaultText = literalExpression ''"/var/lib/wireguard/''${interface}.key"'';
      description = ''
        The hub's private key. To keep the key across a rebuilt droplet,
        store it with sops-nix and point this at the secret's path.
      '';
    };

    generatePrivateKey = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Create {option}`privateKeyFile` with `wg genkey` on first start if it
        does not exist. The key never leaves the machine. Turn this off when
        the key comes from sops, so a missing secret fails the interface
        instead of being replaced by a new key.
      '';
    };

    routeBetweenPeers = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Forward packets that arrive on the tunnel back into it, so spokes can
        reach each other through the hub. Forwarding is enabled for the
        tunnel interface only, not for the public interface.
      '';
    };

    dns.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Serve {option}`domain` with dnsmasq on the hub's tunnel address only.
        It answers for the zone and refuses everything else, so it is not a
        recursive resolver.
      '';
    };

    trustInterface = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Open every port to traffic from the tunnel. When off, the tunnel gets
        what the public interface gets, plus DNS when {option}`dns.enable`
        is on.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = length addresses == length (unique addresses);
        message = "nixlab.networking.wireguard.hosts: two hosts share a tunnel address.";
      }
    ];

    warnings = map (
      name: "nixlab.networking.wireguard: ${name} has no publicKey yet, so it is left out of the tunnel."
    ) withoutKey;

    networking.wireguard.interfaces.${iface} = {
      ips = [ "${hub.address}/${prefixLength}" ];
      inherit (cfg) listenPort privateKeyFile;
      generatePrivateKeyFile = cfg.generatePrivateKey;

      # No endpoint and no keepalive: each spoke dials in, and WireGuard
      # answers it wherever its packets last came from.
      peers = mapAttrsToList (name: host: {
        inherit name;
        inherit (host) publicKey;
        allowedIPs = [ "${host.address}/32" ];
      }) withKey;

      # Forward only what arrives on the tunnel; the global ip_forward stays
      # off, so the droplet never routes between the internet and the tunnel.
      # Redirects are useless on a point-to-point interface.
      postSetup = optionalString cfg.routeBetweenPeers ''
        ${pkgs.procps}/bin/sysctl -q -w \
          net.ipv4.conf.${iface}.forwarding=1 \
          net.ipv4.conf.${iface}.send_redirects=0
      '';
    };

    networking.firewall = {
      allowedUDPPorts = [ cfg.listenPort ];
      trustedInterfaces = mkIf cfg.trustInterface [ iface ];
      interfaces.${iface} = mkIf cfg.dns.enable {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [ 53 ];
      };
    };

    # The hub resolves the names itself without going through DNS.
    networking.hosts = mapAttrs' (
      name: host: nameValuePair host.address (dnsNames name host)
    ) cfg.hosts;

    services.dnsmasq = mkIf cfg.dns.enable {
      enable = true;
      # Leave the droplet's own resolver alone.
      resolveLocalQueries = false;
      settings = {
        # Bind the tunnel address alone, and keep working when the interface
        # comes up after dnsmasq or is recreated.
        listen-address = hub.address;
        bind-dynamic = true;

        # Authoritative for the zone; no upstream servers, so any other name
        # is refused rather than resolved.
        local = "/${cfg.domain}/";
        no-resolv = true;
        no-hosts = true;
        domain-needed = true;
        bogus-priv = true;

        host-record = mapAttrsToList (
          name: host: concatStringsSep "," (dnsNames name host ++ [ host.address ])
        ) cfg.hosts;
      };
    };

    environment.systemPackages = [ pkgs.wireguard-tools ];
  };
}
