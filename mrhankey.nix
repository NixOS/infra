{ config, pkgs, ... }:

{
  require = [ ./common.nix ];

  boot.grubDevice = "/dev/sda";
  boot.initrd.extraKernelModules = [ "mptbase" "mptscsih" "mptsas" ];

  fileSystems = 
    [ { mountPoint = "/";
        label = "nixos";
        fsType = "ext3";
      }
    ];

  swapDevices = [ { label = "swap"; } ];

  networking.hostName = "";

  services.openssh.enable = true;

  services.tomcat = 
    {
      enable = true;
      baseDir = "/data/tomcat";
      javaOpts = "-Dshare.dir=/nix/var/nix/profiles/default/share -Xms350m -Xmx2048m -XX:MaxPermSize=512M -XX:PermSize=512M -XX:-UseGCOverheadLimit";
      logPerVirtualHost = true;
      virtualHosts = 
        [ { name = "test.researchr.org";}
          { name = "test.nixos.org";}
        ];
    };

  services.mysql = 
    {
      enable = true;
      package = pkgs.mysql51;
      dataDir = "/data/mysql";
    };

}
