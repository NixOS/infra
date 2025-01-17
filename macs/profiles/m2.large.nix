{
  # 8 Cores, 24 GB RAM, 1 TB Disk
  # split into 2 jobs with 4C/12G
  nix.settings = {
    cores = 4;
    max-jobs = 2;
  };
}
