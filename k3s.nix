{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.nixlab.virtualization.k3s;
in
{
  options.nixlab.virtualization.k3s = {
    enable = mkEnableOption "K3s Kubernetes distribution";
    isServer = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this node should run as a K3s server";
    };
  };

  config = mkIf cfg.enable {
    services.k3s = {
      enable = true;
      role = if cfg.isServer then "server" else "agent";
      extraFlags = toString [
        "--write-kubeconfig-mode=644"
      ];
    };

    # k3s networking and firewall configuration
    # See: https://docs.k3s.io/installation/requirements#networking
    networking.firewall = {
      # Trust CNI and Flannel interfaces
      trustedInterfaces = [
        "cni0"
        "flannel.1"
      ];

      allowedTCPPorts = [
        6443 # Kubernetes API server
        10250 # Kubelet metrics
      ];

      allowedUDPPorts = [
        8472 # Flannel VXLAN
        51820 # Flannel WireGuard (IPv4)
        51821 # Flannel WireGuard (IPv6)
      ];

      extraCommands = ''
        # Allow all traffic from k3s pod network (10.42.0.0/16)
        iptables -A nixos-fw -s 10.42.0.0/16 -j nixos-fw-accept -m comment --comment "k3s pod network"

        # Allow all traffic from k3s service network (10.43.0.0/16)
        iptables -A nixos-fw -s 10.43.0.0/16 -j nixos-fw-accept -m comment --comment "k3s service network"
      '';
    };
  };
}
