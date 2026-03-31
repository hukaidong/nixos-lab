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

  # base system packages
  environment.systemPackages = with pkgs; [
    bash
    git
    kitty
    vim
    btop
    uutils-coreutils-noprefix
  ];

  services.openssh.enable = true;

  system.stateVersion = "25.11";

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
