{config, pkgs, ...}:

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
  boot = {
    initrd = {
      extraKernelModules = [ "uhci_hcd" "ehci_hcd" "ata_piix" "mptsas" "usbhid" "ext4" ];
    };
    kernelModules = [ "acpi-cpufreq" "kvm-intel" ];
    kernelPackages = pkgs.kernelPackages_2_6_28;
    grubDevice = "/dev/sda";
    copyKernels = true;
  
    localCommands = ''
      echo 60 > /proc/sys/kernel/panic
    '';
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
  };

  services = {

    sshd = {
      enable = true;
    };
      
    cron.systemCronJobs = 
      [ "15 03 * * * root ${pkgs.nixUnstable}/bin/nix-collect-garbage --max-freed $((64 * 1024**3)) > /var/log/gc.log 2>&1"
      ];

  };
}
