{ config, pkgs, lib, ... }:

{
  services.hydra-scale-equinix-metal = {
    enable = true;
    hydraRoot = "https://hydra.nixos.org/";
    prometheusRoot = "https://status.nixos.org/prometheus";
    secretFile = "/root/keys/hydra-scale-equinix-metal-env";
    interval = ["*:0/5"];
    config = let
      netboot_base = https://netboot.nixos.org/dispatch/hydra/hydra.nixos.org/equinix-metal-builders/main;
    in {
      facilities = ["any"];
      tags = ["hydra"];
      categories = {
        aarch64-linux = [
          {
            size = "bigparallel";
            divisor = 5;
            minimum = 1;
            maximum = 5;
            plans = [
              {
                bid = 2.0;
                plan = "c3.large.arm64";
                netboot_url = "${netboot_base}/c3-large-arm--big-parallel";
              }
            ];
          }
          {
            size = "small";
            divisor = 2000;
            minimum = 1;
            maximum = 5;
            plans = [
              {
                bid = 2.0;
                plan = "c3.large.arm64";
                netboot_url = "${netboot_base}/c3-large-arm";
              }
            ];
          }
          # Try to ensure we have at least 1 aarch64-linux builder by bidding slightly higher than
          # usual (the minimum is *intentionally* 0 so that we don't hold onto this "backup" machine
          # once we go below 5000 runnable builds). The goal is that this bid will only go through
          # when we have at least 5000 runnable builds for aarch64-linux, and hopefully prevents us
          # from having 0 aarch64 machines if the spot market prices rise too high.
          # Spot market prices for c3.large.arm64 over the last week:
          # https://monitoring.nixos.org/grafana/d/ItOJVUoWk/packet-spot-prices?var-plan=c3.large.arm64&from=now-7d&to=now&orgId=1&refresh=10s
          # Spot market capacity for c3.large.arm64 over the last 5 minutes:
          # https://monitoring.nixos.org/grafana/d/I1WQEbbWz/packet-capacity-by-plan-table?orgId=1&var-plan=c3.large.arm64&var-facility=All
          {
            size = "small";
            divisor = 5000;
            minimum = 0; # *intentionally* 0 so we don't hold onto this machine forever and skew the spot market prices too high
            maximum = 1;
            plans = [
              {
                bid = 2.5;
                plan = "c3.large.arm64";
                netboot_url = "${netboot_base}/c3-large-arm";
              }
            ];
          }
        ];
        x86_64-linux = [
          {
            size = "bigparallel";
            divisor = 5;
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
          }
          {
            size = "small";
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
          }
        ];
      };
    };
  };
}
