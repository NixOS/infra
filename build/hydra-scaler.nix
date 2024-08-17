{ config, ... }:

{
  services.hydra-scale-equinix-metal = {
    enable = true;
    hydraRoot = "https://hydra.nixos.org/";
    prometheusRoot = "https://status.nixos.org/prometheus";
    secretFile = "/root/keys/hydra-scale-equinix-metal-env";
    interval = ["*:0/5"];
    config = let
      netboot_base = "https://netboot.nixos.org/dispatch/hydra/hydra.nixos.org/equinix-metal-builders/main";
    in {
      metro = "any";
      tags = ["hydra"];
      categories = {
        # NOTE(cole-h): We don't autoscale arm64 anymore because EM asked us not to: the arm64 spot
        # market appears to be a little funky as of this comment (we would commonly spin up a
        # machine, only for it to be reclaimed before it was even able to boot into NixOS and run
        # even 1 build for Hydra).
        # As of 17 Feb 2024, we have 2 dedicated arm64 machines on EM -- one `small`
        # (`small-c3.large.arm64`) and one `big-parallel` (`big-parallel-c3.large.arm64`). Hopefully
        # this will be an improvement over "maybe we have no arm64 machines at all because they spin
        # down before they can do any work".
        # The netboot URL for arm64 big-parallel is: https://netboot.nixos.org/dispatch/hydra/hydra.nixos.org/equinix-metal-builders/main/c3-large-arm--big-parallel ("Always PXE" enabled, "hydra" tag)
        # The netboot URL for arm64 small is: https://netboot.nixos.org/dispatch/hydra/hydra.nixos.org/equinix-metal-builders/main/c3-large-arm ("Always PXE" enabled, "hydra" tag)

        x86_64-linux = rec {
          bigparallel = {
            divisor = 16;
            minimum = 1;
            maximum = 4;
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
            maximum = 3;
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
