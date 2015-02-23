{ config, pkgs, ... }:

{
  require =
    [ ./common.nix
      ./hydra-module.nix
      ./hydra-mirror.nix
      ./megacli.nix
      ./datadog.nix
      ./datadog/hydra.nix
    ];

  nixpkgs.system = "x86_64-linux";

  environment.systemPackages =
    [ pkgs.wget pkgs.megacli config.boot.kernelPackages.sysdig ];

  networking.hostName = "lucifer";
  networking.firewall.allowedTCPPorts = [ 2049 3000 4000 ];

  networking.interfaces.enx842b2b0b98f1 =
    { ipAddress = "172.16.25.81";
      prefixLength = 21;
    };

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;
  boot.initrd.kernelModules = [ "uhci_hcd" "ehci_hcd" "ata_piix" "megaraid_sas" "usbhid" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];
  boot.extraModulePackages = [config.boot.kernelPackages.sysdig];

  services.hydra.enable = true;
  services.hydra.logo = ./hydra-logo.png;
  services.hydra.tracker = ''
    <!-- Start of StatCounter Code -->
    <script type=\"text/javascript\">
      var sc_project=6818408;
      var sc_invisible=1;
      var sc_security=\"8838c8ed\";
    </script>
    <script type=\"text/javascript\"
      src=\"http://www.statcounter.com/counter/counter.js\"></script>
    <noscript><div class=\"statcounter\"><a title=\"visit tracker
    on tumblr\" href=\"http://statcounter.com/tumblr/\"
    target=\"_blank\"><img class=\"statcounter\"
    src=\"http://c.statcounter.com/6818408/0/8838c8ed/1/\"
    alt=\"visit tracker on tumblr\"></a></div></noscript>
    <!-- End of StatCounter Code -->
  '';

  fileSystems."/".device = "/dev/disk/by-label/nixos";

  fileSystems."/fatdata" =
    { device = "/dev/fatdisk/fatdata";
      neededForBoot = true;
    };

  fileSystems."/nix" =
    { device = "/fatdata/nix";
      fsType = "none";
      options = "bind";
      neededForBoot = true;
    };

  fileSystems."/nix/var/nix" =
    { device = "/nix-data";
      fsType = "none";
      options = "bind";
      neededForBoot = true;
    };

  fileSystems."/data".device = "/dev/disk/by-label/data";


  fileSystems."/backup-tud" =
    { device = "172.16.26.5://vol/vol_backup_linux_fbs_ewi_buildfarm_lucifer/qt_backup_linux_fbs_ewi_buildfarm_lucifer";
      fsType = "nfs4";
    };

  services.nfs.server.enable = true;
  services.nfs.server.exports =
    ''
      /data/releases 192.168.1.0/255.255.255.0(ro,no_root_squash,fsid=0,no_subtree_check)
    '';

  nixpkgs.config.subversion.pythonBindings = true;

  services.cron.systemCronJobs =
    let
      # Run the garbage collector on ‘machine’ to ensure that at least
      # ‘gbFree’ GiB are free.
      gcRemote = { machine, gbFree ? 8, df ? "df" }:
        "15 03 * * *  root  ssh -x -i /root/.ssh/id_buildfarm ${machine} " +
        ''nix-store --gc --max-freed '$((${toString gbFree} * 1024**3 - 1024 * $(${df} -P -k /nix/store | tail -n 1 | awk "{ print \$4 }")))' > "/var/log/gc-${machine}.log" 2>&1'';
    in
    [ (gcRemote { machine = "nix@butters"; gbFree = 50; })
      (gcRemote { machine = "nix@garrison"; })
      (gcRemote { machine = "nix@demon"; })
      (gcRemote { machine = "nix@beastie"; })
      (gcRemote { machine = "nix@tweek"; gbFree = 3; df = "/usr/gnu/bin/df"; })
    ];

  # Set some cgroup limits.
  systemd.services.sshd.serviceConfig.CPUShares = 2000;
  systemd.services.sshd.serviceConfig.BlockIOWeight = 1000;
  systemd.services.nix-daemon.serviceConfig.CPUShares = 200;
  systemd.services.nix-daemon.serviceConfig.BlockIOWeight = 500;
  systemd.services.hydra-queue-runner.serviceConfig.CPUShares = 200;
  systemd.services.hydra-queue-runner.serviceConfig.BlockIOWeight = 200;
  systemd.services.hydra-evaluator.serviceConfig.CPUShares = 100;
  systemd.services.hydra-evaluator.serviceConfig.BlockIOWeight = 100;
  systemd.services.hydra-server.serviceConfig.CPUShares = 700;
  systemd.services.hydra-server.serviceConfig.BlockIOWeight = 700;

  nix.sshServe.enable = true;
  nix.sshServe.keys = with import ../ssh-keys.nix; [ eelco rob ];

  systemd.services.nix-compress-logs =
    { script =
        ''
          touch -d 'last month' /root/.r
          find /nix/var/log/nix/drvs -type f -a ! -newer /root/.r -name '*.drv' | xargs bzip2 -v
        '';
      startAt = "Sun 01:45";
    };

}
