{
  config,
  ...
}:

{
  imports = [
    ./nginx.nix
  ];

  fileSystems."/var/lib/owncast" = {
    device = "zroot/root/owncast";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  services.backups.includeZfsDatasets = [
    "/var/lib/owncast"
  ];

  services.owncast = {
    enable = true;
    openFirewall = true;
  };

  services.nginx.virtualHosts."live.nixos.org" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = with config.services.owncast; "http://${listen}:${toString port}";
      proxyWebsockets = true;
    };
  };
}
