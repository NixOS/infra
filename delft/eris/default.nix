{ lib
, modulesPath
, ...
}:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    ../common.nix
    ./boot.nix
    ./network.nix
  ];
  
  networking = {
    hostName = "eris";
    domain = "nixos.org";
  };

  fileSystems = {
    "/" = {
      fsType = "ext4";
      label = "root";
    };
  };

  swapDevices = [
    { label = "swap1"; }
    { label = "swap2"; }
  ];

  systemd.units."mdmonitor.service".enable = false;

  services.fstrim.enable = true;

  nix.settings.max-jobs = lib.mkDefault 8;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  system.stateVersion = "18.03";
}
