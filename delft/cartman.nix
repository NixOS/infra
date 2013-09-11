{ config, pkgs, ... }:

with pkgs.lib;

let

  duplicityBackup = pkgs.writeScript "backup-duplicity" ''
    #! /bin/sh
    echo "Starting backups"
    export PATH=$PATH:/var/run/current-system/sw/bin
    time duplicity --full-if-older-than 30D --no-encryption /data/pt-wiki file:///backup/cartman/pt-wiki
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/pt-wiki

    time duplicity --full-if-older-than 30D --no-encryption /data/subversion file:///backup/cartman/subversion
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/subversion

    time duplicity --full-if-older-than 30D --no-encryption /data/subversion-ptg file:///backup/cartman/subversion-ptg
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/subversion-ptg

    time duplicity --full-if-older-than 30D --no-encryption /data/subversion-strategoxt file:///backup/cartman/subversion-strategoxt
    time duplicity --no-encryption --force remove-all-inc-of-but-n-full 1 file:///backup/cartman/subversion-strategoxt

    echo Done
  '';

  ZabbixApacheUpdater = pkgs.fetchsvn {
    url = https://www.zulukilo.com/svn/pub/zabbix-apache-stats/trunk/fetch.py;
    sha256 = "1q66x429wpqjqcmlsi3x37rkn95i55nj8ldzcrblnx6a0jnjgd2g";
    rev = 94;
  };

in

rec {
  require = [ ./common.nix ];

  nixpkgs.system = "x86_64-linux";

  boot = {
    loader.grub.device = "/dev/sda";
    loader.grub.copyKernels = true;
    initrd.kernelModules = ["arcmsr"];
    kernelModules = ["kvm-intel"];
  };

  fileSystems."/" =
    { label = "nixos";
      options = "acl";
    };
  fileSystems."/backup" =
    { device = "130.161.158.5:/dxs/users4/group/buildfarm";
      fsType = "nfs4";
    };

  #swapDevices = [ { label = "swap1"; } ];

  nix.maxJobs = 2;

  services.cron.mailto = "rob.vermaas@gmail.com";
  services.cron.systemCronJobs =
    [ #"15 0 * * *  root  (TZ=CET date; ${pkgs.rsync}/bin/rsync -razv --numeric-ids --delete /data/postgresql /data/webserver/tarballs unixhome.st.ewi.tudelft.nl::bfarm/) >> /var/log/backup.log 2>&1"
      "*  *  * * * root ${pkgs.python}/bin/python ${ZabbixApacheUpdater} -z 192.168.1.5 -c cartman"
      "40 * * * *  root ${duplicityBackup} &>> /var/log/backup-duplicity.log"
    ];

  environment.systemPackages = [ pkgs.duplicity ];
}
