# Server profile
# Pre-composed module set for cloud/server deployments
{ config, ... }:

{
  nixlab = {
    auth.secure.enable = true;
    services.k3s.enable = true;
    services.k3s.isServer = true;
  };
}
