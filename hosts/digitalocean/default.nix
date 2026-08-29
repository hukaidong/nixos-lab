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
  # two privileged operations nixos-rebuild needs (`nix-env --set` on the
  # system profile and `systemd-run ... switch-to-configuration`) without an
  # interactive prompt. Deploy with `--sudo`, not `--ask-sudo-password`.
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

    services.grocy.enable = true;
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
