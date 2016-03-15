{ config, pkgs, ... }:

{

  systemd.services.fstrim =
    { description = "Trim SSD Disks";
      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStart = "${pkgs.utillinux}/bin/fstrim -a -v";
      startAt = "02:35";
     };

}
