{ lib, pkgs, ... }:
let
  channels = builtins.attrNames (import ../../channels.nix).channels;
in {
  systemd.services.channel-update-exporter = {
    description = "Check all active channels' last-update times";
    path = [ (pkgs.python3.withPackages (pypkgs: with pypkgs; [ requests dateutil prometheus_client ])) ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${./channel-exporter.py} ${lib.concatStringsSep " " channels}";
    };
  };
}