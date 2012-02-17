{ config, pkgs, ... }:

{
  require = [ ./common.nix ./hydra-module.nix ./hydra-mirror.nix ];

  nixpkgs.system = "x86_64-linux";

  environment.systemPackages = [ pkgs.wget ];

  networking.hostName = "lucifer";

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;
  boot.initrd.kernelModules = [ "uhci_hcd" "ehci_hcd" "ata_piix" "megaraid_sas" "usbhid" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];

  services.hydra.enable = true;
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

  services.nfsKernel.server.enable = true;
  services.nfsKernel.server.exports =
    ''
      /data/releases 192.168.1.0/255.255.255.0(ro,no_root_squash,fsid=0)
    '';

  nixpkgs.config.subversion.pythonBindings = true;

  services.hydraChannelMirror.enable = true;
  services.hydraChannelMirror.enableBinaryPatches = true;
  services.hydraChannelMirror.period = "0-59/15 * * * *";
  services.hydraChannelMirror.dataDir = "/data/releases";

  /*
  services.tomcat = {
    enable = true;
    baseDir = "/data/tomcat";
    javaOpts = 
      "-Dshare.dir=/nix/var/nix/profiles/default/share -Xms350m -Xss8m -Xmx1024m -XX:MaxPermSize=512M -XX:PermSize=512M -XX:-UseGCOverheadLimit "
      + "-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=localhost "
      + "-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/tomcat/logs/java_pid<pid>.hprof";
  };
  */

  services.cron.systemCronJobs =
    let
      # Run the garbage collector on ‘machine’ to ensure that at least
      # ‘gbFree’ GiB are free.
      gcRemote = { machine, gbFree ? 3, df ? "df" }:
        "15 03 * * *  root  ssh -x -i /root/.ssh/id_buildfarm ${machine} " +
        ''nix-store --gc --max-freed '$((${toString gbFree} * 1024**3 - 1024 * $(${df} -P -k /nix/store | tail -n 1 | awk "{ print \$4 }")))' > "/var/log/gc-${machine}.log" 2>&1'';
    in
    [ "*/5 * * * *  hydra-mirror  flock -x /data/releases/.lock -c /home/hydra-mirror/release/mirror/mirror-nixos-isos.sh >> /home/hydra-mirror/nixos-mirror.log 2>&1" 
      (gcRemote { machine = "nix@butters"; })
      (gcRemote { machine = "nix@garrison"; })
      (gcRemote { machine = "nix@demon"; })
      (gcRemote { machine = "nix@beastie"; })
      (gcRemote { machine = "nix@tweek"; gbFree = 2; df = "/usr/gnu/bin/df"; })
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

}
