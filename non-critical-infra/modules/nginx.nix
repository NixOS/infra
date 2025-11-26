{
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

  # Grant nginx access to certificates
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [ "acme" ];

  # Reload nginx after certificate renewal
  security.acme.defaults.reloadServices = [ "nginx.service" ];

  services.nginx = {
    enable = true;
    enableReload = true;

    recommendedBrotliSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };
}
