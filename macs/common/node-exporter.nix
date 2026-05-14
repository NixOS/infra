{
  lib,
  ...
}:

{
  services.prometheus.exporters.node.enable = true;

  # https://github.com/LnL7/nix-darwin/issues/1256
  users.users._prometheus-node-exporter.home = lib.mkForce "/private/var/lib/prometheus-node-exporter";
}
