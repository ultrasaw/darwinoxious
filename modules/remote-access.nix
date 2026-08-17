{ unstablePkgs, ... }:

{
  services.tailscale = {
    enable = true;
    package = unstablePkgs.tailscale;
  };
}
