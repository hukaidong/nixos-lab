# VM test of the WireGuard hub (modules/networking/wireguard.nix).
#
#   vlan 1 ("internet"): hub 192.168.1.1, laptop 192.168.1.2, router 192.168.1.4
#   vlan 2 ("home LAN"): mac 192.168.2.3, router 192.168.2.4 (NAT to vlan 1)
#
# `mac` stands in for the Mac Studio: a wg-quick spoke behind NAT, set up like
# etc-nixos' darwin/networking/wireguard.nix sets up the real one. `laptop` is
# a second spoke with a public address. The hub knows neither endpoint.
#
# Run with `nix build .#checks.x86_64-linux.wireguard -L`.
{ lib, ... }:

let
  # Throwaway keys for this test only; never use them anywhere else.
  keys = {
    hub = {
      privateKey = "kIhU5bcK+3UWgZ3uTDSUtnlqvmxtUGyrP9h3VYTD4Ho=";
      publicKey = "LjJ6u0v9nKL/EbjN/E+ekULSGfBZ0uJfc30JlRqs9Gw=";
    };
    mac = {
      privateKey = "2JK6EuaxAzBW1A06PFlmqMoQ0Ey48rS1nYK0O00BHnY=";
      publicKey = "NnwvZ74Y0FSiN/78ZzSYDXMwM07phJKDCBULwb2h0h0=";
    };
    laptop = {
      privateKey = "EElrZzfPyHy+WDxtmweQR2gL6JTORCJ1JD8SKdW+lWc=";
      publicKey = "WXrkCQwHNC3Z9f4MtfhYpub5DbkE5PGvpa/3UR8v7Rw=";
    };
  };

  # A spoke as the etc-nixos darwin module configures one.
  spoke =
    {
      address,
      key,
      vlan,
      gateway ? null,
    }:
    { pkgs, ... }:
    {
      virtualisation.vlans = [ vlan ];
      networking.useDHCP = false;
      networking.defaultGateway = lib.mkIf (gateway != null) gateway;

      networking.wg-quick.interfaces.wg0 = {
        address = [ "${address}/24" ];
        privateKeyFile = "${pkgs.writeText "spoke.key" key.privateKey}";
        peers = [
          {
            inherit (keys.hub) publicKey;
            endpoint = "192.168.1.1:51820";
            allowedIPs = [ "10.77.0.0/24" ];
            persistentKeepalive = 25;
          }
        ];
      };

      environment.systemPackages = [
        pkgs.dig
        pkgs.wireguard-tools
      ];
    };
in
{
  name = "nixlab-wireguard";

  nodes = {
    hub =
      { pkgs, ... }:
      {
        imports = [ ../modules/networking/wireguard.nix ];
        virtualisation.vlans = [ 1 ];
        networking.useDHCP = false;

        nixlab.networking.wireguard = {
          enable = true;
          self = "digix";
          # A fixed key, as on the droplet (which reads its key from sops).
          generatePrivateKey = false;
          privateKeyFile = "${pkgs.writeText "hub.key" keys.hub.privateKey}";
          hosts = {
            digix = {
              address = "10.77.0.1";
              aliases = [ "chat" ];
            };
            mac-studio = {
              address = "10.77.0.2";
              inherit (keys.mac) publicKey;
            };
            laptop = {
              address = "10.77.0.3";
              inherit (keys.laptop) publicKey;
            };
            # Listed before its key exists: in DNS, but not a peer yet.
            pending.address = "10.77.0.9";
          };
        };

        environment.systemPackages = [ pkgs.dig ];
      };

    router = {
      virtualisation.vlans = [
        1
        2
      ];
      networking.useDHCP = false;
      networking.nat = {
        enable = true;
        externalInterface = "eth1";
        internalInterfaces = [ "eth2" ];
      };
    };

    mac = spoke {
      address = "10.77.0.2";
      key = keys.mac;
      vlan = 2;
      gateway = "192.168.2.4";
    };

    laptop = spoke {
      address = "10.77.0.3";
      key = keys.laptop;
      vlan = 1;
    };
  };

  testScript = ''
    start_all()

    hub.wait_for_unit("wireguard-wg0.service")
    hub.wait_for_unit("dnsmasq.service")
    router.wait_for_unit("network.target")
    mac.wait_for_unit("wg-quick-wg0.service")
    laptop.wait_for_unit("wg-quick-wg0.service")

    with subtest("the NAT is real: the hub cannot reach the home LAN directly"):
        hub.fail("ping -c1 -W1 192.168.2.3")

    with subtest("mac, behind NAT, reaches the hub over the tunnel"):
        mac.wait_until_succeeds("ping -c1 -W2 10.77.0.1", timeout=120)

    with subtest("the hub reaches mac at the NAT's address it learned"):
        hub.succeed("ping -c1 -W2 10.77.0.2")
        hub.succeed("wg show wg0 endpoints | grep -F '192.168.1.4:'")

    with subtest("a host without a public key is not a peer"):
        hub.succeed("test \"$(wg show wg0 peers | wc -l)\" -eq 2")

    with subtest("spokes reach each other through the hub"):
        laptop.wait_until_succeeds("ping -c1 -W2 10.77.0.1", timeout=120)
        laptop.succeed("ping -c1 -W2 10.77.0.2")
        mac.succeed("ping -c1 -W2 10.77.0.3")

    with subtest("forwarding is on for the tunnel only"):
        hub.succeed("test \"$(sysctl -n net.ipv4.ip_forward)\" = 0")
        hub.succeed("test \"$(sysctl -n net.ipv4.conf.eth1.forwarding)\" = 0")
        hub.succeed("test \"$(sysctl -n net.ipv4.conf.wg0.forwarding)\" = 1")

    with subtest("the hub serves the zone over the tunnel"):
        mac.succeed("dig +short @10.77.0.1 digix.wg.internal | grep -x 10.77.0.1")
        mac.succeed("dig +short @10.77.0.1 chat.wg.internal | grep -x 10.77.0.1")
        mac.succeed("dig +short @10.77.0.1 pending.wg.internal | grep -x 10.77.0.9")
        laptop.succeed("dig +short @10.77.0.1 mac-studio.wg.internal | grep -x 10.77.0.2")
        mac.succeed("dig +short @10.77.0.1 -x 10.77.0.3 | grep -x laptop.wg.internal.")

    with subtest("the zone's DNS is not a recursive resolver"):
        mac.succeed("dig @10.77.0.1 example.com | grep -E 'status: (REFUSED|SERVFAIL)'")

    with subtest("DNS is not served on the public address"):
        laptop.fail("dig +time=2 +tries=1 @192.168.1.1 digix.wg.internal")

    with subtest("the hub resolves the names itself"):
        hub.succeed("getent hosts mac-studio.wg.internal | grep -F 10.77.0.2")

    with subtest("mac reconnects after the hub restarts and forgets its endpoint"):
        hub.systemctl("restart wireguard-wg0.service")
        hub.wait_for_unit("wireguard-wg0.service")
        # The restarted hub drops mac's keepalives, which belong to the old
        # session; keepalives never start a handshake. mac starts one when its
        # session is 2 minutes old, or sooner if it sends data, and only then
        # does the hub learn where mac is.
        hub.wait_until_succeeds("ping -c1 -W2 10.77.0.2", timeout=240)
        mac.succeed("dig +short @10.77.0.1 digix.wg.internal | grep -x 10.77.0.1")
  '';
}
