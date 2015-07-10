{ config, lib, pkgs, ... }:

with lib;

{
  imports =
    [ ./common.nix
      ../../hydra/hydra-module.nix
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

  fileSystems."/".device = "/dev/disk/by-label/nixos";

  fileSystems."/fatdata" =
    { device = "/dev/fatdisk/fatdata";
      neededForBoot = true;
      options = "defaults,noatime";
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
  systemd.services.hydra-queue-runner.serviceConfig.BlockIOWeight = 700;
  systemd.services.hydra-evaluator.serviceConfig.CPUShares = 100;
  systemd.services.hydra-evaluator.serviceConfig.BlockIOWeight = 100;
  systemd.services.hydra-server.serviceConfig.CPUShares = 700;
  systemd.services.hydra-server.serviceConfig.BlockIOWeight = 200;

  nix.sshServe.enable = true;
  nix.sshServe.keys = with import ../ssh-keys.nix; [ eelco rob ];

  users.extraUsers.hydra.openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco rob ];
  users.extraUsers.hydra-www.openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco rob ];
  users.extraUsers.hydra-queue-runner.openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco rob ];

  users.extraUsers.rbvermaa =
    { description = "Rob Vermaas";
      home = "/home/rbvermaa";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ (import ../ssh-keys.nix).rob ];
    };

  nix.gc.automatic = true;
  nix.gc.options = ''--max-freed "$((700 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';

  # Hydra configuration.
  services.hydra.enable = true;
  services.hydra.logo = ./hydra-logo.png;
  services.hydra.dbi = "dbi:Pg:dbname=hydra;host=wendy;user=hydra;";
  services.hydra.hydraURL = "http://hydra.nixos.org";
  services.hydra.notificationSender = "e.dolstra@tudelft.nl"; # FIXME
  services.hydra.extraConfig =
    ''
      max_servers 50
      enable_persona 1

      binary_cache_secret_key_file = /var/lib/hydra/www/keys/hydra.nixos.org-1/secret

      <hipchat>
        jobs = (hydra|nixops):.*:.*
        room = 182482
        token = ${builtins.readFile ./hipchat-lb-token}
      </hipchat>

      <Plugin::Session>
        cache_size = 32m
      </Plugin::Session>
    '';

  #services.hydra.package = builtins.storePath /nix/store/qrd493zbpnk8hqs2pc01jac0l715xsd4-hydra-0.1pre1234-abcdef;

  users.extraUsers.hydra.home = mkForce "/home/hydra";

}
