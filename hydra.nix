{ config, pkgs, ... }:

let

  machines = import ./machines.nix pkgs.lib;

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

  nixpkgs.system = "x86_64-linux";

  environment.nix = pkgs.nixSqlite;

  boot = {
    initrd.kernelModules = [ "mptsas" "ext4" ];
    kernelModules = [ "acpi-cpufreq" "kvm-intel" ];
    loader.grub.device = "/dev/sda";
    loader.grub.copyKernels = true;
  };

  fileSystems =
    [ { mountPoint = "/";
        label = "nixos";
        options = "noatime,barrier=0,data=ordered";
      }
    ];
 
  #swapDevices = [ { label = "swap" ; } ];

  nix = {
    maxJobs = 8;

    inherit buildMachines;

    extraOptions = ''
      gc-keep-outputs = true
      gc-keep-derivations = true

      # The default (`true') slows Nix down a lot since the build farm
      # has so many GC roots.
      gc-check-reachability = false

      # Hydra needs caching of build failures.
      build-cache-failure = true

      build-poll-interval = 10

      use-sqlite-wal = false
    '';
  };

  networking = {
    hostName = "hydra";
    domain = "buildfarm";
  };

  services.cron.systemCronJobs =
    [
      # Make sure that at least 200 GiB of disk space is available.
      "15 3 * * * root  nix-store --gc --max-freed \"$((200 * 1024**3 - 1024 * $(df /nix/store | tail -n 1 | awk '{ print $4 }')))\" > /var/log/gc.log 2>&1"
    ];

}
