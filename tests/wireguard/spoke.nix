# A spoke node as etc-nixos' darwin module configures one: wg-quick with the
# hub as its only peer, dialling the hub's public address and keeping the path
# open through NAT.
#
#   spoke { address = "10.77.0.2"; key = keys.mac; vlan = 2; gateway = "192.168.2.4"; }
{
  address,
  key,
  vlan,
  gateway ? null,
}:
{ lib, pkgs, ... }:
let
  keys = import ./keys.nix;
in
{
  virtualisation.vlans = [ vlan ];

  networking = {
    useDHCP = false;
    defaultGateway = lib.mkIf (gateway != null) gateway;

    wg-quick.interfaces.wg0 = {
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
  };

  environment.systemPackages = [
    pkgs.dig
    pkgs.wireguard-tools
  ];
}
