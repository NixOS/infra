{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  sopsFile = ../../secrets/nixpkgs-update.yaml;

  nixpkgs-update-bin = "/var/lib/nixpkgs-update/bin/nixpkgs-update";

  nixpkgsUpdateSystemDependencies = with pkgs; [
    config.nix.package
    git # used by update-scripts
    git-lfs
    openssh # used by git
    gnugrep
    gnused
    curl
    getent # used by hub
    apacheHttpd # for rotatelogs, used by worker script
    socat # used by worker script

    coreutils
    gist
    nixpkgs-review
    nix-eval-jobs
    tree
  ];

  mkWorker = name: {
    after = [
      "network-online.target"
      config.systemd.services.nixpkgs-update-supervisor.name
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ config.systemd.targets.multi-user.name ];
    description = "nixpkgs-update ${name} service";
    enable = true;
    restartIfChanged = true;
    path = nixpkgsUpdateSystemDependencies;
    environment.XDG_CONFIG_HOME = "/var/lib/nixpkgs-update/worker";
    environment.XDG_CACHE_HOME = "/var/cache/nixpkgs-update/worker";
    environment.XDG_RUNTIME_DIR = "/run/nixpkgs-update-worker"; # for nix-update update scripts

    serviceConfig = {
      Type = "simple";
      User = "r-ryantm";
      Group = "r-ryantm";
      Restart = "on-failure";
      RestartSec = "5s";
      WorkingDirectory = "/var/lib/nixpkgs-update/worker";
      StateDirectory = "nixpkgs-update/worker";
      StateDirectoryMode = "700";
      CacheDirectory = "nixpkgs-update/worker";
      CacheDirectoryMode = "700";
      LogsDirectory = "nixpkgs-update/";
      LogsDirectoryMode = "755";
      RuntimeDirectory = "nixpkgs-update-worker";
      RuntimeDirectoryMode = "700";
      StandardOutput = "journal";
    };

    environment.NIXPKGS_UPDATE_BIN = nixpkgs-update-bin;
    environment.WORKER_NAME = name;

    script = builtins.readFile ./worker.bash;
  };

  mkFetcher = name: cmd: {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = nixpkgsUpdateSystemDependencies ++ [
      # nixpkgs-update-github-releases
      (pkgs.python3.withPackages (
        p: with p; [
          requests
          python-dateutil
          libversion
          cachecontrol
          lockfile
          filelock
        ]
      ))
    ];
    # API_TOKEN is used by nixpkgs-update-github-releases
    # using a token from another account so the rate limit doesn't block opening PRs
    environment.API_TOKEN_FILE = "${config.sops.secrets.github-token-with-username.path}";
    environment.XDG_CACHE_HOME = "/var/cache/nixpkgs-update/fetcher/";

    serviceConfig = {
      Type = "simple";
      User = "r-ryantm";
      Group = "r-ryantm";
      Restart = "on-failure";
      RestartSec = "30m";
      LogsDirectory = "nixpkgs-update/";
      LogsDirectoryMode = "755";
      StateDirectory = "nixpkgs-update";
      StateDirectoryMode = "700";
      CacheDirectory = "nixpkgs-update/fetcher";
      CacheDirectoryMode = "700";
    };

    script = ''
      set -eo pipefail
      mkdir -p "$LOGS_DIRECTORY/~fetchers"
      mkdir -p "$LOGS_DIRECTORY/~fetchers_history"
      cd "$LOGS_DIRECTORY/~fetchers"
      run_name="${name}.$(date +%s)"
      rm -f ${name}.*.txt.part
      ${cmd} | tee "$LOGS_DIRECTORY/~fetchers_history/$run_name-unprocessed.txt" | sed -f ${./filter.sed} > "$run_name.txt.part"
      rm -f ${name}.*.txt
      cp "$run_name.txt.part" "$LOGS_DIRECTORY/~fetchers_history/$run_name.txt"
      mv "$run_name.txt.part" "$run_name.txt"
    '';
    startAt = "0/12:10"; # every 12 hours
  };

  repology = pkgs.writeShellApplication {
    name = "repology";
    runtimeInputs = [
      pkgs.jq
      pkgs.moreutils
    ];
    text = builtins.readFile ./repology.bash;
  };
in
{
  imports = [
    ../../../modules/nspawn-test-containers.nix
  ];

  users.groups.r-ryantm = { };
  users.users.r-ryantm = {
    useDefaultShell = true;
    isNormalUser = true; # The hub cli seems to really want stuff to be set up like a normal user
    uid = 5469; # 1000 + digits of "rrtm", kept from the previous host
    extraGroups = [ "r-ryantm" ];
  };

  systemd.services.nixpkgs-update-delete-done = {
    startAt = "0/12:10"; # every 12 hours
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    description = "nixpkgs-update delete done branches";
    restartIfChanged = true;
    path = nixpkgsUpdateSystemDependencies;
    environment.XDG_CONFIG_HOME = "/var/lib/nixpkgs-update/worker";
    environment.XDG_CACHE_HOME = "/var/cache/nixpkgs-update/worker";

    serviceConfig = {
      Type = "simple";
      User = "r-ryantm";
      Group = "r-ryantm";
      Restart = "on-abort";
      RestartSec = "5s";
      WorkingDirectory = "/var/lib/nixpkgs-update/worker";
      StateDirectory = "nixpkgs-update/worker";
      StateDirectoryMode = "700";
      CacheDirectoryMode = "700";
      LogsDirectory = "nixpkgs-update/";
      LogsDirectoryMode = "755";
      StandardOutput = "journal";
    };

    script = "${nixpkgs-update-bin} delete-done --delete";
  };

  systemd.services.nixpkgs-update-fetch-github =
    mkFetcher "github" "${inputs.nixpkgs-update-github-releases}/main.py"
    // {
      startAt = "0/6:10"; # every 6 hours
    };
  systemd.services.nixpkgs-update-fetch-repology = mkFetcher "repology" (lib.getExe repology);
  systemd.services.nixpkgs-update-fetch-updatescript = mkFetcher "updatescript" "${lib.getExe config.nix.package} eval --option max-call-depth 100000 --raw -f ${./packages-with-update-script.nix}";

  systemd.services.nixpkgs-update-worker1 = mkWorker "worker1";
  systemd.services.nixpkgs-update-worker2 = mkWorker "worker2";
  systemd.services.nixpkgs-update-worker3 = mkWorker "worker3";
  systemd.services.nixpkgs-update-worker4 = mkWorker "worker4";
  systemd.services.nixpkgs-update-worker5 = mkWorker "worker5";
  systemd.services.nixpkgs-update-worker6 = mkWorker "worker6";
  # Too many workers cause out-of-memory.

  systemd.services.nixpkgs-update-supervisor = {
    wantedBy = [ config.systemd.targets.multi-user.name ];
    description = "nixpkgs-update supervisor service";
    enable = true;
    restartIfChanged = true;
    path = with pkgs; [
      apacheHttpd
      (python3.withPackages (ps: [ ps.asyncinotify ]))
    ];

    serviceConfig = {
      Type = "simple";
      User = "r-ryantm";
      Group = "r-ryantm";
      Restart = "on-failure";
      RestartSec = "5s";
      LogsDirectory = "nixpkgs-update/";
      LogsDirectoryMode = "755";
      RuntimeDirectory = "nixpkgs-update-supervisor/";
      RuntimeDirectoryMode = "755";
      StandardOutput = "journal";
    };

    script = ''
      mkdir -p "$LOGS_DIRECTORY/~supervisor"
      # This is for public logs at nixpkgs-update-logs.nixos.org/~supervisor
      exec  > >(rotatelogs -eD "$LOGS_DIRECTORY"'/~supervisor/%Y-%m-%d.stdout.log' 86400)
      exec 2> >(rotatelogs -eD "$LOGS_DIRECTORY"'/~supervisor/%Y-%m-%d.stderr.log' 86400 >&2)
      # Fetcher output is hosted at nixpkgs-update-logs.nixos.org/~fetchers
      python3 ${./supervisor.py} "$LOGS_DIRECTORY/~supervisor/state.db" "$LOGS_DIRECTORY/~fetchers" "$RUNTIME_DIRECTORY/work.sock"
    '';
  };

  systemd.services.nixpkgs-update-queue = {
    after = [ config.systemd.services.nixpkgs-update-supervisor.name ];
    wantedBy = [ config.systemd.targets.multi-user.name ];

    serviceConfig = {
      Type = "simple";
      User = "r-ryantm";
      Group = "r-ryantm";
      Restart = "on-failure";
      RestartSec = "5s";
      LogsDirectory = "nixpkgs-update/";
      LogsDirectoryMode = "755";
      RuntimeDirectory = "nixpkgs-update-queue";
      RuntimeDirectoryMode = "755";
    };

    path = [ pkgs.python3 ];

    script = ''
      cd "$LOGS_DIRECTORY/~supervisor"
      python3 ${./update_queue.py}
    '';
  };

  systemd.services.nixpkgs-update-metrics = {
    startAt = "*:0/5";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.python3} ${./metrics.py} /var/log/nixpkgs-update/~supervisor/state.db /var/lib/prometheus-node-exporter-text-files/nixpkgs-update.prom";
      ReadWritePaths = [ "/var/lib/prometheus-node-exporter-text-files" ];
      ProtectSystem = "strict";
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.services.nixpkgs-update-delete-old-logs = {
    startAt = "daily";
    # delete logs older than 9 months
    # delete fetchers_history older than a month
    # delete worker logs older than 3 months
    # delete empty directories
    script = ''
      find /var/log/nixpkgs-update -type f -mtime +270 -delete
      find /var/log/nixpkgs-update/~fetchers_history -type f -mtime +30 -delete
      find /var/log/nixpkgs-update/~workers -type f -mtime +90 -delete
      find /var/log/nixpkgs-update -type d -empty -delete
    '';
    path = [ pkgs.findutils ];
    serviceConfig.Type = "oneshot";
  };

  systemd.tmpfiles.rules = [
    "L+ /home/r-ryantm/.gitconfig - - - - ${./gitconfig.txt}"
    "d /home/r-ryantm/.ssh 700 r-ryantm r-ryantm - -"

    "e /var/cache/nixpkgs-update/worker/nixpkgs-review - - - 1d -"

    "d /var/lib/nixpkgs-update/bin/ 700 r-ryantm r-ryantm - -"
    "L+ ${nixpkgs-update-bin} - - - - ${
      inputs.nixpkgs-update.packages.${pkgs.stdenv.hostPlatform.system}.default
    }/bin/nixpkgs-update"
  ];

  sops.secrets.github-r-ryantm-key = {
    inherit sopsFile;
    path = "/home/r-ryantm/.ssh/id_rsa";
    owner = "r-ryantm";
    group = "r-ryantm";
  };

  sops.secrets.github-r-ryantm-token = {
    inherit sopsFile;
    path = "/var/lib/nixpkgs-update/worker/github_token.txt";
    owner = "r-ryantm";
    group = "r-ryantm";
  };

  sops.secrets.github-token-with-username = {
    inherit sopsFile;
    owner = "r-ryantm";
    group = "r-ryantm";
  };

  services.nginx.virtualHosts."nixpkgs-update-logs.nixos.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      alias = "/var/log/nixpkgs-update/";
      extraConfig = ''
        charset utf-8;
        autoindex on;
      '';
    };
  };

  # TODO: permanent redirect r.ryantm.com/log/ -> nixpkgs-update-logs.nixos.org
  services.nginx.virtualHosts."r.ryantm.com" = {
    enableACME = true;
    forceSSL = true;
    locations."/log/" = {
      alias = "/var/log/nixpkgs-update/";
      extraConfig = ''
        charset utf-8;
        autoindex on;
      '';
    };
  };

}
