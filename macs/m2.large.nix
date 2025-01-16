{
  # 8C, 24 GB, 1 TB
  # split into 2 jobs with 4C/12G
  nix.settings = {
    cores = 4;
    max-jobs = 2;
  };
}
