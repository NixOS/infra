{
  hardware.rasdaemon = {
    enable = true;
    record = true;
  };

  services.prometheus.exporters.rasdaemon = {
    enable = true;
    enabledCollectors = [
      "aer"
      "mce"
      "mc"
      "extlog"
      "devlink"
      "disk"
    ];
    openFirewall = true;
  };
}
