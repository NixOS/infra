{ pkgs, ...}:
{
  environment.systemPackages = [ pkgs.sysstat ];

  services.cron.systemCronJobs =
    [ "*/1 * * * * root mkdir -p /var/log/sa; ${pkgs.sysstat}/lib/sa/sa1 -S DISK 1 1"
      "53 23 * * * root mkdir -p /var/log/sa; ${pkgs.sysstat}/lib/sa/sa2 -A"
    ];
}
