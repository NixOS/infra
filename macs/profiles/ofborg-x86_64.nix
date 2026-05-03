{
  # 12 Cores, 32GB RAM, 1 TB Disk
  # split into 4 jobs with 3C/8G
  nix.settings = {
    cores = 3;
    max-jobs = 4;
  };
}
