{
  # 8C, 16 GB, 256 GB
  # split into 4 jobs with 2C/4G
  nix.settings = {
    cores = 2;
    max-jobs = 4;
  };
}
