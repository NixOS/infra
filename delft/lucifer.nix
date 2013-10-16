{ config, pkgs, ... }:

{
  require = [ ./common.nix ./hydra-module.nix ./megacli.nix ];

  nixpkgs.system = "x86_64-linux";

  environment.systemPackages =
    [ pkgs.wget
      pkgs.perlPackages.DBDSQLite pkgs.perlPackages.NetAmazonS3 pkgs.perlPackages.ForksSuper pkgs.nodePackages.jsontool # for hydra-mirror
      pkgs.python pkgs.pythonPackages.boto # for upload-binary-cache-s3.py
      pkgs.megacli
    ];

  networking.hostName = "lucifer";
  networking.firewall.allowedTCPPorts = [ 2049 3000 4000 ];

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;
  boot.initrd.kernelModules = [ "uhci_hcd" "ehci_hcd" "ata_piix" "megaraid_sas" "usbhid" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];

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

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
      }
      { mountPoint = "/fatdata";
        device = "/dev/fatdisk/fatdata";
        neededForBoot = true;
      }
      { mountPoint = "/nix";
        device = "/fatdata/nix";
        fsType = "none";
        options = "bind";
        neededForBoot = true;
      }
      { mountPoint = "/data";
        label = "data";
      }
    ];

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

  systemd.services.mirror-nixpkgs =
    { description = "Mirror Nixpkgs";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      path = [ pkgs.su ];
      script =
        ''
          rm -rf /data/releases/nixpkgs/.tmp-*
          exec su - hydra-mirror -c 'cd release/channels; while true; do ./mirror-nixpkgs.sh; sleep 1200; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };

  /*
  systemd.services.generate-nixpkgs-patches =
    { description = "Generate Nixpkgs Patches";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.su ];
      script =
        ''
          exec su - hydra-mirror -c 'cd release/channels; while true; do ./generate-linear-patch-sequence.sh; sleep 300; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };
  */

  systemd.services.mirror-nixos =
    { description = "Mirror NixOS";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      path = [ pkgs.su ];
      script =
        ''
          rm -rf /data/releases/nixos/.tmp-*
          exec su - hydra-mirror -c 'cd release/channels; while true; do ./mirror-nixos.sh; sleep 1200; done'
        '';
      serviceConfig.Restart = "always";
      serviceConfig.CPUShares = 100;
    };

}
