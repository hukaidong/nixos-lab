# Doom Emacs editor support
{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.nixlab.editors.doom-emacs;
  install-doomemacs = pkgs.writeShellScriptBin "install-doomemacs" ''
    set -euo pipefail

    if [ -d "$HOME/.emacs.d" ] || [ -d "$HOME/.doom.d" ]; then
      echo "Doom Emacs is already installed."
      exit 0
    fi

    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
    ~/.config/emacs/bin/doom install

    echo 'export PATH="$HOME/.config/emacs/bin:$PATH"' >> $HOME/.profile
    echo "Doom Emacs installed successfully. Please restart your terminal or source your profile."
  '';
in
{
  options.nixlab.editors.doom-emacs = {
    enable = mkEnableOption "Doom Emacs support";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      emacs
      install-doomemacs

      # prerequisites for doomemacs
      git
      fd
      ripgrep
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.symbols-only
    ];
  };
}
