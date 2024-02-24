{ lib
, config
, ...
}:

let
  cfg = config.services.backup;
in
{
  options.services.backup = with lib; with types; {
    user = mkOption {
      type = str;
      description = ''
        Username for the SSH remote host.
      '';
    };

    host = mkOption {
      type = str;
      description = ''
        Hostname of the SSH remote host.
      '';
    };

    hostPublicKey = mkOption {
      type = str;
      example = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
      description = ''
        Public SSH host key of the remote host. Discoverable using e.g. `ssh-keyscan`.
      '';
    };

    port = mkOption {
      type = port;
      default = 22;
      description = ''
        Port of the SSH remote host.
      '';
      apply = toString;
    };

    sshKey = mkOption {
      type = path;
      example = "/var/keys/ssh-key";
      description = ''
        Path to the SSH key required to access the remote host.
      '';
    };

    secretPath = mkOption {
      type = path;
      example = "/var/keys/borg-secret";
      description = ''
        Path to the secret used to encrypt backups in the repository.
      '';
    };

    quota = mkOption {
      type = nullOr str;
      default = null;
      example = "90G";
      description = ''
        Quota for the borg repository. Useful to prevent the target disk from running full and ensuring borg keeps some space to work with.
      '';
    };

    includes = mkOption {
      type = listOf path;
      default = [];
      description = ''
        Paths to include in the backup.
      '';
    };

    excludes = mkOption {
      type = listOf path;
      default = [];
      description = ''
        Paths to exclude in the backup.
      '';
    };

    preHook = mkOption {
      type = lines;
      default = "";
      description = ''
        Shell commands to run before the backup.
      '';
    };

    postHook = mkOption {
      type = lines;
      default = "";
      description = ''
        Shell commands to run after the backup.
      '';
    };

    wantedUnits = mkOption {
      type = listOf str;
      default = [];
      description = ''
        List of units to require before starting the backup.
      '';
    };
  };

  config = lib.mkIf (cfg.includes != []) {
    programs.ssh.knownHosts."${if cfg.port != 22 then "[${cfg.host}]:${cfg.port}" else cfg.host}" = {
      publicKey = "${cfg.hostPublicKey}";
    };

    systemd.services.borgbackup-job-state = {
      wants = cfg.wantedUnits;
      after = cfg.wantedUnits;
    };

    systemd.timers.borgbackup-job-state.timerConfig = {
      # Spread all backups over the day
      RandomizedDelaySec = "24h";
      FixedRandomDelay = true;
    };

    services.borgbackup.jobs.state = {
      inherit (cfg) preHook postHook;

      # Create the repo
      doInit = true;

      # Create daily backups, but prune to a reasonable amount
      startAt = "daily";
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 3;
      };

      # What to backup
      paths = cfg.includes;
      exclude = cfg.excludes;

      # Where to backup it to
      repo = "${cfg.user}@${cfg.host}:${config.networking.fqdn}";
      environment.BORG_RSH = "ssh -p ${cfg.port} -i ${cfg.sshKey}";

      # Ensure we don't fill up the destination disk
      extraInitArgs = lib.optionalString (cfg.quota != null) "--storage-quota ${cfg.quota}";

      # Authenticated & encrypted, key resides in the repository
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${cfg.secretPath}";
      };

      # Reduce the backup size
      compression = "auto,zstd";

      # Show summary detailing data usage once completed
      extraCreateArgs = "--stats";
    };
  };
}
