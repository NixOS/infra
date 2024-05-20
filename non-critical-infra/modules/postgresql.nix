{ config
, pkgs
, ...
}:

{
  fileSystems."/var/lib/postgresql" = {
    device = "zroot/root/postgresql";
    fsType = "zfs";
    options = [
      "zfsutil"
    ];
  };

  services.postgresql = {
    enable = true;
    enableJIT = true;
    package = pkgs.postgresql_16_jit;
  };

  # create database dumps
  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    # pulled in through the backup job
    startAt = [];
  };

  # include postgres dumps in the backup
  services.backup = {
    includes = [
      "/var/backup/postgresql"
    ];
    wantedUnits = if config.services.postgresqlBackup.databases == [] then
      [ "postgresqlBackup.service" ]
    else
      map (db: "postgresqlBackup-${db}.service") config.services.postgresqlBackup.databases;
  };
}
