{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    atop
    ethtool
    htop
    lm_sensors
    nix-top
    nvme-cli
    pciutils
    smartmontools
    usbutils
  ];
}
