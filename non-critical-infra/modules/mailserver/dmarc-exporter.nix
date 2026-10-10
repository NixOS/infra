{
  config,
  ...
}:

{
  sops.secrets.dmarc-exporter-imap-password = {
    format = "binary";
    sopsFile = ../../secrets/dmarc-exporter-imap-password.umbriel;
  };

  systemd.services.prometheus-dmarc-exporter.serviceConfig.LoadCredential = [
    "password:${config.sops.secrets."dmarc-exporter-imap-password".path}"
  ];

  services.prometheus.exporters.dmarc = {
    enable = true;
    listenAddress = "::";
    imap = {
      username = "dmarc@nixos.org";
      host = "umbriel.nixos.org";
      passwordFile = "$CREDENTIALS_DIRECTORY/password";
    };
    openFirewall = true;
    firewallRules = ''
      ip6 saddr $prometheus_inet6 tcp dport ${toString config.services.prometheus.exporters.dmarc.port} accept
      ip saddr $prometheus_inet4 tcp dport ${toString config.services.prometheus.exporters.dmarc.port} accept
    '';
  };
}
