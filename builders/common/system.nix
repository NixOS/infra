{
  pkgs,
  ...
}:

{
  # apply microcode to fix functional and security issues
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = pkgs.stdenv.isx86_64;
  hardware.cpu.intel.updateMicrocode = pkgs.stdenv.isx86_64;

  # enable kernel same-page merging for improved vm test performance
  hardware.ksm.enable = true;

  # discard blocks weekly
  services.fstrim.enable = true;

  # use memory more efficiently at the cost of some compute
  zramSwap.enable = true;

  # enable huge pages for tmpfs on /tmp
  boot.tmp.tmpfsHugeMemoryPages = "within_size";
}
