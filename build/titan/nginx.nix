{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    eventsConfig = ''
      worker_connections 4096;
    '';
  };
}
