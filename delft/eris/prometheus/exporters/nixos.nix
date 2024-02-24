{
  services.prometheus.scrapeConfigs = [ {
    job_name = "nixos";
    static_configs = [ {
      labels.role = "hydra";
      targets = [
        "rhea:9300"
      ];
    } {
      labels.role = "monitoring";
      targets = [
        "eris:9300"
        "pluto:9300"
      ];
    } {
      labels.role = "database";
      targets = [
        "haumea:9300"
      ];
    } {
      labels.role = "bastion";
      targets = [
        "bastion:9300"
      ];
    } ];
  } ];
}
