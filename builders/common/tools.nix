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
    nvme-cli
    pciutils
    smartmontools
    usbutils
  ];
}
