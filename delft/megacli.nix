{ config, pkgs, ...}:
{
  environment.systemPackages = [ pkgs.megacli ];

  security.sudo.configFile =
    ''
      zabbix ALL=(ALL) NOPASSWD: ${pkgs.megacli}/bin/MegaCli64
    '';
}
