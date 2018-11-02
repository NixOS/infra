{ config, pkgs, ...}:
{
  environment.systemPackages = [ pkgs.megacli ];
}
