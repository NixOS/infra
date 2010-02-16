{ config, pkgs, ... }:

let

  machines = import ./machines.nix;

  # Produce the list of Nix build machines in the format expected by
  # the Nix daemon Upstart job.
  buildMachines =
    let addKey = machine: machine // 
      { sshKey = "/root/.ssh/id_buildfarm";
        sshUser = machine.buildUser;
      };
    in map addKey (pkgs.lib.filter (machine: machine ? buildUser) machines);

in

{
  require = [ ./common.nix ];

  boot = {
    initrd = {
      extraKernelModules = [ "uhci_hcd" "ehci_hcd" "ata_piix" "mptsas" "usbhid" "ext4" ];
    };
    kernelModules = [ "acpi-cpufreq" "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_2_6_32;
    grubDevice = "/dev/sda";
    copyKernels = true;
  };

  fileSystems = [
    { mountPoint = "/"; 
      label = "nixos";
      options = "noatime";
    }
  ];
 
  swapDevices = [
    { label = "swap" ; }
  ];

  nix = {
    maxJobs = 0;
    distributedBuilds = true;
    inherit buildMachines;

    extraOptions = ''
      gc-keep-outputs = true

      # The default (`true') slows Nix down a lot since the build farm
      # has so many GC roots.
      gc-check-reachability = false

      # Hydra needs caching of build failures.
      build-cache-failure = true

      build-poll-interval = 10
    '';
  };

  networking = {
    hostName = "hydra";
    domain = "buildfarm";

    extraHosts = 
      let toHosts = m: "${m.ipAddress} ${m.hostName} ${pkgs.lib.concatStringsSep " " (if m ? aliases then m.aliases else [])}\n"; in
      pkgs.lib.concatStrings (map toHosts machines);

    defaultMailServer = {
      directDelivery = true;
      hostName = "smtp.st.ewi.tudelft.nl";
      domain = "st.ewi.tudelft.nl";
    };
  };

  services = {
    httpd.enable = true;
    httpd.adminAddr = "rob.vermaas@gmail.com";

    systemhealth = {
      enable = true;
      interfaces = [ "lo" "eth0" ];
      drives = [
        { name = "root"; path = "/"; }
      ];
    };

    cron.systemCronJobs = 
      [ "15 02 * * * hydra source /home/hydra/.bashrc; /nix/var/nix/profiles/per-user/hydra/profile/bin/hydra_update_gc_roots.pl > /home/hydra/gc-roots.log 2>&1"
        # Make sure that at least 100 GiB of disk space is available.
        "15 03 * * * root  nix-store --gc --max-freed \"$((250 * 1024**3 - 1024 * $(df /nix/store | tail -n 1 | awk '{ print $4 }')))\" > /var/log/gc.log 2>&1"
      ];

  };
}
