{ pkgs, ...}:
{
  environment.systemPackages = [ pkgs.sysstat ];

  services.cron.systemCronJobs =
    [ "*/1 * * * * root ${pkgs.sysstat}/lib/sa/sa1 -S DISK 1 1"
      "53 23 * * * root ${pkgs.sysstat}/lib/sa/sa2 -A"
    ];

  systemd.services."sysstat-init" =
    { description = "Create sysstat directory";
      wantedBy = [ "multi-user.target" ];
      script =
        ''
        mkdir -p /var/log/sa
        '';
      serviceConfig =
        { Type = "oneshot";
          RemainAfterExit = true;
        };
    };
}
