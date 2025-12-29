# Auth modules - import both, enable one
{
  imports = [
    ./trusted.nix
    ./secure.nix
  ];
}
