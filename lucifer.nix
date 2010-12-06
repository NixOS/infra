{ config, pkgs, ... }:

{
  require = [ ./common.nix ];

  networking.hostName = "lucifer";

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;
  boot.initrd.kernelModules = [ "uhci_hcd" "ehci_hcd" "ata_piix" "megaraid_sas" "usbhid" ];
  boot.kernelModules = [ "acpi-cpufreq" "kvm-intel" ];

  fileSystems = 
    [ { mountPoint = "/";
        label = "nixos";
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

  #services.hydraChannelMirror.enable = true;
  services.hydraChannelMirror.period = "0-59/15 * * * *";

  services.cron.systemCronJobs =
    [ "0-59/15 * * * * hydra-mirror perl -I/home/hydra-mirror/nix/inst/libexec/nix ~/release/channels/mirror-channel.pl http://hydra.nixos.org/jobset/nixpkgs/trunk/channel/latest /data/releases/nixpkgs/channels/nixpkgs-unstable /data/releases/nars http://nixos.org/releases/nars /data/releases/patches http://nixos.org/releases/patches http://hydra.nixos.org/job/nixpkgs/trunk/tarball/latest/download-by-type/file/source-dist >> /var/log/nixpkgs-unstable.log 2>&1"
    ];

  /*
  services.httpd.enable = true;
  services.httpd.adminAddr = "rob.vermaas@gmail.com";
  */

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    dataDir = "/data/postgresql";
    authentication = 
      ''
        local all mediawiki        ident mediawiki-users
        local all all              ident sameuser
        host  all all 127.0.0.1/32 md5
        host  all all ::1/128      md5
        host  all all 192.168.1.0/24 md5
      ''; 
  };

  nix.gc.automatic = true;
  nix.gc.options = "--max-freed $((100 * 1024**3))";

  services.tomcat = {
    enable = true;
    baseDir = "/data/tomcat";
    javaOpts = 
      "-Dshare.dir=/nix/var/nix/profiles/default/share -Xms350m -Xss8m -Xmx1024m -XX:MaxPermSize=512M -XX:PermSize=512M -XX:-UseGCOverheadLimit "
      + "-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=8999 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=localhost "
      + "-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/tomcat/logs/java_pid<pid>.hprof";
  };

}
