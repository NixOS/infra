import <nixpkgs/nixos> {
configuration = { pkgs, lib, config, ... }: {
    imports = [
      ./host/default.nix
    ];
    nixpkgs.config.allowUnfree = true;

    fileSystems."/" =
      { device = "rpool/root";
        fsType = "zfs";
      };

    networking.hostId = "aaaaaaaa";
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "dummy";
    macosGuest.guest = {
      cores = 2;
      threads = 2;
      sockets = 2;
      memoryInMegs = 6 * 1024;

      zvolName = "rpool/example";
      guestConfigDir = ./guest;

      ovmfCodeFile = ./dist/OVMF_CODE.fd;
      ovmfVarsFile = ./dist/OVMF_VARS-1024x768.fd;
      cloverImage = ./dist/Clover.qcow2;
    };
  };
}
