# Digital Ocean droplet configuration
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules
    ../../profiles/base.nix
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4 * 1024; # 4GiB
    }
  ];

  fileSystems."/nix" = {
    device = "/dev/disk/by-id/scsi-0DO_Volume_digix-nix-store";
    fsType = "ext4";
    options = [
      "noatime"
      "discard"
    ];
    neededForBoot = true;
  };

  boot.loader.grub.copyKernels = true;

  # base system packages
  environment.systemPackages = with pkgs; [
    bash
    git
    vim
    btop
    uutils-coreutils-noprefix
  ];

  services.openssh.enable = true;

  # Allow passwordless sudo for the deploy user so remote deploys can run the
  # two privileged operations nh needs (`nix-env --set` on the system profile
  # and `systemd-run ... switch-to-configuration`) without an interactive
  # prompt. The `deploy` helper uses `--elevation-strategy passwordless`.
  security.sudo.extraRules = [
    {
      users = [ "kaidong" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  system.stateVersion = "26.05";

  nix.optimise.automatic = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";

  # digital Ocean-specific module configuration
  nixlab = {
    auth.secure.enable = true;

    services.grocy.enable = false;
    services.sftpgo.enable = true;
    services.open-webui.enable = true;
    services.open-webui.environment = {
      RAG_EMBEDDING_ENGINE = "openai";
      AUDIO_STT_ENIGNE = "webapi";
      ENABLE_AUTOCOMPLETE_GENERATION = "False";
      ENABLE_FOLLOW_UP_GENERATION = "False";
    };

    services.nginx = {
      enable = true;
      enableCfSSL = true;
    };

    # The hub's WireGuard private key, kept with sops in secrets/secret.yaml
    # so it survives a rebuilt droplet.
    secrets = {
      enable = true;
      wireguard.enable = true;
    };

    # Private network with the home machines; this droplet is the hub. The
    # table is the address book for every machine on it (and the
    # wg.internal DNS zone). The hub reads its private key from sops and
    # never generates one, so a missing secret stops the tunnel instead of
    # changing its public key. Every other machine creates its own key;
    # paste its public key here once it has one.
    networking.wireguard = {
      enable = true;
      self = "digix";
      privateKeyFile = config.sops.secrets."wireguard.key".path;
      generatePrivateKey = false;
      hosts = {
        digix = {
          address = "10.77.0.1";
          publicKey = "La77HxNKrh5nw1+rW3lOcvw/vnefyeWyleOs+abFhnI=";
        };
        mac-studio = {
          address = "10.77.0.2";
          publicKey = "Eka6Bp1F49KjOEd4C8A26IcEcAKILGcjQFfHumO+rVk=";
        };
      };
    };
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "sftpgo"
      "open-webui"
    ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-public-keys = [
      "digix-build:MUfI7WSJIrQb+kNaTnVw1mYMeWBvoi0Ovb9eWPc+enM="
    ];

    trusted-users = [ "kaidong" ];
  };
}
