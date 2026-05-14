{
  # Prune the Rosetta JIT bytecode cache
  # Probably purges more than that, see
  # https://github.com/nix-darwin/nix-darwin/pull/1165#issuecomment-2477157627
  launchd.daemons.rosetta2-gc = {
    script = ''
      date
      exec /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -P -minsize 0 /System/Volumes/Data
    '';
    serviceConfig.StartInterval = 3600 * 2;
    serviceConfig.RunAtLoad = true;
    serviceConfig.StandardErrorPath = "/var/log/rosetta2-gc.log";
    serviceConfig.StandardOutPath = "/var/log/rosetta2-gc.log";
  };

  # MacOS stores extensive logs in /var/db/uuidtext, which cause high disk usage
  # Manually: find /var/db/uuidtext -type f -mtime +7 -delete
  launchd.daemons.log-erase = {
    script = ''
      date
      log erase --all
    '';
    serviceConfig.StartInterval = 3600 * 24;
    serviceConfig.StandardErrorPath = "/var/log/uuidtext-gc.log";
    serviceConfig.StandardOutPath = "/var/log/uuidtext-gc.log";
  };

  # Regularly kill fseventsd to reclaim excessively leaked memory/swap
  launchd.daemons.fseventsd-reclaim = {
    script = ''
      killall -9 fseventsd
    '';
    serviceConfig.StartInterval = 3600;
  };
}
