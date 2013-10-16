{ config, pkgs, ...}:
{
  environment.systemPackages = [ pkgs.megacli ];

  security.sudo.configFile =
    ''
      zabbix ALL=(ALL) NOPASSWD: ${pkgs.megacli}/bin/MegaCli64
    '';

  services.zabbixAgent.extraConfig =
    ''
      UserParameter=megaraid[*],/var/setuid-wrappers/sudo ${pkgs.megacli}/bin/MegaCli64 -pdInfo -PhysDrv[$2:$3] -a$1 | grep '$4' | cut -f2 -d':' | cut -b2-
      UserParameter=megaraid.degraded,/var/setuid-wrappers/sudo ${pkgs.megacli}/bin/MegaCli64 -AdpAllInfo -aAll -NoLog | grep -A 2 'Virtual Drives' | grep Degraded | ${pkgs.gawk}/bin/awk '/Degraded/ {TOTAL += $3} END {print TOTAL}'
    '';
}
