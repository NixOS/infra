{
  imports = [
    ../../modules/nginx.nix
  ];

  services.nginx.virtualHosts."core01.ofborg.org" = {
    forceSSL = true;
    enableACME = true;

    locations."= /metrics/node".proxyPass = "http://[::1]:9100/metrics";
    locations."= /metrics/rabbitmq".proxyPass = "http://[::1]:15692/metrics";
  };
}
