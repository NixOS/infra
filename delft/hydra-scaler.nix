{ config, pkgs, lib, ... }: {
  deployment.keys."hydra-scale-equinix-metal-env".keyFile = /home/deploy/src/nixos-org-configurations/keys/hydra-scale-equinix-metal-env;
  services.hydra-scale-equinix-metal = {
    enable = true;
    hydraRoot = "https://hydra.nixos.org/";
    prometheusRoot = "https://status.nixos.org/prometheus";
    secretFile = "/run/keys/hydra-scale-equinix-metal-env";
    config = let
      netboot_base = https://netboot.nixos.org/dispatch/hydra/hydra.nixos.org/equinix-metal-builders/main;
    in {
      facilities = ["any"];
      tags = ["hydra"];
      categories = {
        aarch64-linux = rec {
          bigparallel = {
            divisor = 2000;
            minimum = 1;
            maximum = 5;
            plans = [
              {
                bid = 2.0;
                plan = "c3.large.arm64";
                netboot_url = "${netboot_base}/c3-large-arm--big-parallel";
              }
            ];
          };
          small = bigparallel // {
            plans = [
              {
                bid = 2.0;
                plan = "c3.large.arm64";
                netboot_url = "${netboot_base}/c3-large-arm";
              }
            ];
          };
        };
        x86_64-linux = rec {
          bigparallel = {
            divisor = 2000;
            minimum = 1;
            maximum = 5;
            plans = [
              {
                bid = 2.0;
                netboot_url = "${netboot_base}/c3-medium-x86--big-parallel";
                plan = "c3.medium.x86";
              }
              {
                bid = 2.0;
                netboot_url = "${netboot_base}/m3-large-x86--big-parallel";
                plan = "m3.large.x86";
              }
            ];
          };
          small = {
            divisor = 2000;
            minimum = 1;
            maximum = 5;
            plans = [
              {
                bid = 2.0;
                netboot_url = "${netboot_base}/c3-medium-x86";
                plan = "c3.medium.x86";
              }
              {
                bid = 2.0;
                netboot_url = "${netboot_base}/m3-large-x86";
                plan = "m3.large.x86";
              }
            ];
          };
        };
      };
    };
  };
}
