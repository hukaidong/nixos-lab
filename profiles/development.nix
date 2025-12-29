# Development workstation profile
# Pre-composed module set for local development VMs
{ config, ... }:

{
  nixlab = {
    auth.trusted.enable = true;
    desktop.xfce.enable = true;
    editors.doom-emacs.enable = true;
  };
}
