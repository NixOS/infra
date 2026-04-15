{
  # 8 Cores, 16 GB RAM, 256 GB Disk
  # split into 4 jobs with 2C/4G
  nix.settings = {
    cores = 2;
    max-jobs = 4;
  };
}
