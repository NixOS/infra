{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  channels = (import ../channels.nix).channels-with-urls;

  orderLib = import ../lib/service-order.nix { };

  makeUpdateChannel = channelName: mainJob: {
    name = "update-${channelName}";
    value = {
      description = "Update Channel ${channelName}";
      path = with pkgs; [
        git
        inputs.nixos-channel-scripts.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
      script = ''
        # Hardcoded in channel scripts.
        dir=/home/hydra-mirror/nixpkgs-channels
        if ! [[ -e $dir ]]; then
          git clone --bare https://github.com/NixOS/nixpkgs.git $dir
        fi
        GIT_DIR=$dir git config credential.helper 'store --file=${config.age.secrets.hydra-mirror-git-credentials.path}'
        GIT_DIR=$dir git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

        # FIXME: use IAM role.
        export AWS_ACCESS_KEY_ID=$(sed 's/aws_access_key_id=\(.*\)/\1/ ; t; d' ${config.age.secrets.hydra-mirror-aws-credentials.path})
        export AWS_SECRET_ACCESS_KEY=$(sed 's/aws_secret_access_key=\(.*\)/\1/ ; t; d' ${config.age.secrets.hydra-mirror-aws-credentials.path})
        exec mirror-nixos-branch ${channelName} https://hydra.nixos.org/job/${mainJob}/latest-finished
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = false;
        User = "hydra-mirror";
        # Allow the unit to use 80% of the system's RAM and 100% of the system's swap
        MemoryHigh = "80%";
      };
      unitConfig = {
        After = [ "networking.target" ];
      };
      environment.TMPDIR = "/home/hydra-mirror/scratch";
      environment.GC_INITIAL_HEAP_SIZE = "4g";
    };
  };

  updateJobs = orderLib.mkOrderedChain (lib.mapAttrsToList makeUpdateChannel channels);

in

{
  age.secrets.hydra-mirror-aws-credentials = {
    file = ../build/secrets/hydra-mirror-aws-credentials.age;
    owner = "hydra-mirror";
  };

  age.secrets.hydra-mirror-git-credentials = {
    file = ../build/secrets/hydra-mirror-git-credentials.age;
    owner = "hydra-mirror";
  };

  users.users.hydra-mirror = {
    description = "Channel mirroring user";
    home = "/home/hydra-mirror";
    createHome = true;
    isSystemUser = true;
    group = "hydra-mirror";
  };

  users.groups.hydra-mirror = { };

  systemd.tmpfiles.rules = [
    ''
      d /home/hydra-mirror/scratch                    0755 hydra-mirror users 10d
      F /home/hydra-mirror/scratch/nixos-files.sqlite - - - 8d
      e /home/hydra-mirror/scratch/release-*/*        - - - 1d -
    ''
  ];

  systemd.services = (lib.listToAttrs updateJobs) // {
    "update-all-channels" = {
      description = "Start all channel updates.";
      unitConfig = {
        After = builtins.map (service: "${service.name}.service") updateJobs;
        Wants = builtins.map (service: "${service.name}.service") updateJobs;
      };
      script = "true";
    };
  };

  systemd.timers."update-all-channels" = {
    description = "Start all channel updates.";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitInactiveSec = 600;
      OnBootSec = 900;
      AccuracySec = 300;
    };
  };
}
