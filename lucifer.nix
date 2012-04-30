{ config, pkgs, ... }:

{
  require = [ ./common.nix ./hydra-module.nix ];

  nixpkgs.system = "x86_64-linux";

  environment.systemPackages = [ pkgs.wget ];

  networking.hostName = "lucifer";

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
      gcRemote = { machine, gbFree ? 4, df ? "df" }:
        "15 03 * * *  root  ssh -x -i /root/.ssh/id_buildfarm ${machine} " +
        ''nix-store --gc --max-freed '$((${toString gbFree} * 1024**3 - 1024 * $(${df} -P -k /nix/store | tail -n 1 | awk "{ print \$4 }")))' > "/var/log/gc-${machine}.log" 2>&1'';
    in
    [ (gcRemote { machine = "nix@butters"; gbFree = 50; })
      (gcRemote { machine = "nix@garrison"; })
      (gcRemote { machine = "nix@demon"; })
      (gcRemote { machine = "nix@beastie"; })
      (gcRemote { machine = "nix@tweek"; gbFree = 3; df = "/usr/gnu/bin/df"; })
    ];

  services.cgroups = {
    enable = true;
    groups =
      ''
        mount {
          cpu = /dev/cgroup/cpu;
          blkio = /dev/cgroup/blkio;
        }
        group hydra-server {
          cpu {
            cpu.shares = "700";
          }
        }
        group hydra-build {
          cpu {
            cpu.shares = "200";
          }
          blkio {
            blkio.weight = "500";
          }
        }
        group hydra-evaluator {
          cpu {
            cpu.shares = "100";
          }
        }
        group hydra-mirror {
          cpu {
            cpu.shares = "100";
          }
        }
      '';
    rules =
      ''
        root:nix-worker cpu,blkio hydra-build
        root:build-remote.pl cpu,blkio hydra-build
        hydra:nix-store cpu,blkio hydra-build
        hydra:.hydra_build.pl-wrapped cpu,blkio hydra-build
        hydra:.hydra_evaluator.pl-wrapped cpu hydra-evaluator
        hydra:.hydra_server.pl-wrapped cpu hydra-server
        hydra-mirror cpu hydra-mirror
      '';
  };

  jobs."mirror-nixpkgs" =
    { startOn = "started networking";
      path = [ pkgs.su ];
      script =
        ''
          su - hydra-mirror -c 'exec >> nixpkgs-mirror.log 2>&1; rm -rf /data/releases/nixpkgs/.tmp-*; cd release/channels; while true; do date; ./mirror-nixpkgs.sh; sleep 300; done'
        '';
    };

  jobs."generate-nixpkgs-patches" =
    { startOn = "started networking";
      path = [ pkgs.su ];
      script =
        ''
          su - hydra-mirror -c 'exec >> nixpkgs-patches.log 2>&1; cd release/channels; while true; do date; ./generate-linear-patch-sequence.sh; sleep 300; done'
        '';
    };

  jobs."mirror-nixos" =
    { startOn = "started networking";
      path = [ pkgs.su ];
      script =
        ''
          su - hydra-mirror -c 'exec >> nixos-mirror.log 2>&1; rm -rf /data/releases/nixos/.tmp-*; cd release/channels; while true; do date; ./mirror-nixos.sh; sleep 300; done'
        '';
    };

}
