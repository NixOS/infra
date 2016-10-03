{ pkgs, ...}:
{
  environment.systemPackages = [ pkgs.sysstat ];

  systemd.services.sa1 =
    { script =
        ''
          mkdir -p /var/log/sa
          exec ${pkgs.sysstat}/lib/sa/sa1 -S DISK 1 1
        '';
      serviceConfig.Type = "oneshot";
      startAt = "*:1";
    };

  systemd.services.sa2 =
    { path = [ pkgs.xz ];
      script =
        ''
          mkdir -p /var/log/sa
          exec ${pkgs.sysstat}/lib/sa/sa2 -A
        '';
      serviceConfig.Type = "oneshot";
      startAt = "23:53";
    };
}
