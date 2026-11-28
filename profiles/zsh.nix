# Zsh shell with Oh My Zsh and Powerlevel10k
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    zsh
    oh-my-zsh
    zsh-powerlevel10k
  ];

  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
    };
    promptInit = "source ''${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
  };
}
