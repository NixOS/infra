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

  environment.nix = pkgs.nixSqlite;

  boot = {
    initrd.kernelModules = [ "uhci_hcd" "ehci_hcd" "ata_piix" "mptsas" "usbhid" "ext4" ];
    kernelModules = [ "acpi-cpufreq" "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_2_6_32;
    loader.grub.device = "/dev/sda";
    loader.grub.copyKernels = true;
  };

  fileSystems =
    [ { mountPoint = "/"; 
        label = "nixos";
        options = "noatime,barrier=0";
      }
    ];
 
  #swapDevices = [ { label = "swap" ; } ];

  nix = {
    maxJobs = 0;
    distributedBuilds = true;
    manualNixMachines = true;

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

  services.cron.systemCronJobs = 
    [ "15 02 * * * hydra source /home/hydra/.bashrc; /nix/var/nix/profiles/per-user/hydra/profile/bin/hydra_update_gc_roots.pl > /home/hydra/gc-roots.log 2>&1"
      # Make sure that at least 200 GiB of disk space is available.
      "15 03 * * * root  nix-store --gc --max-freed \"$((200 * 1024**3 - 1024 * $(df /nix/store | tail -n 1 | awk '{ print $4 }')))\" > /var/log/gc.log 2>&1"
    ];

  jobs.hydra_server = 
    { name = "hydra-server";
      startOn = "started network-interfaces";
      exec = "${pkgs.su}/bin/su - hydra -c 'hydra_server.pl > /home/hydra/data/server.log 2>&1'";
    };

  jobs.hydra_evaluator = 
    { name = "hydra-evaluator";
      startOn = "started network-interfaces";
      exec = "${pkgs.su}/bin/su - hydra -c 'hydra_evaluator.pl > /home/hydra/data/evaluator.log 2>&1'";
    };

  jobs.hydra_queue_runner = 
    { name = "hydra-queue-runner";
      startOn = "started network-interfaces";
      exec = "${pkgs.su}/bin/su - hydra -c 'hydra_queue_runner.pl > /home/hydra/data/queue_runner.log 2>&1'";
    };

}
