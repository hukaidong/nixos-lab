# Settings every nixlab host takes. Importing this file is what turns them on,
# so a host lists it in its imports; nothing here is gated by an option.
# Features a host switches on one by one are option modules in ../modules.
{
  _class = "nixos";

  imports = [
    ./journal.nix
    ./zsh.nix
  ];
}
