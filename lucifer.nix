{ config, pkgs, ... }:

{
  require = [ ./common.nix] ;

  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.copyKernels = true;
  boot.initrd.kernelModules = [  "uhci_hcd" "ehci_hcd" "ata_piix" "megaraid_sas" "usbhid" ];
  boot.kernelModules = ["acpi-cpufreq" "kvm-intel" "coretemp"];

  fileSystems = 
    [ { mountPoint = "/";
        label = "nixos";
      }
      { mountPoint = "/data";
        label = "data";
      }    
    ];

  nixpkgs.config.subversion.pythonBindings = true;

  services.hydraChannelMirror.enable = true;
  services.hydraChannelMirror.period = "0-59/15 * * * *";

  services.httpd.enable = true;
  services.httpd.adminAddr = "rob.vermaas@gmail.com";
  services.httpd.virtualHosts = [ 
        { hostName = "localhost";
          servedDirs = [
            { urlPath = "/releases";
              dir = "/data/hydra-mirror/channels/";
            }
          ];
        }
    ];

}

