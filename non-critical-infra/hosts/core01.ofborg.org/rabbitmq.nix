{ config, ... }:

{
  services.rabbitmq = {
    enable = true;
    plugins = [
      "rabbitmq_shovel"
      "rabbitmq_shovel_management"
      # https://www.rabbitmq.com/docs/prometheus#overview-prometheus
      "rabbitmq_prometheus"
      # https://www.rabbitmq.com/docs/management
      "rabbitmq_management"
      # ofborg-viewer, https://www.rabbitmq.com/docs/web-stomp
      "rabbitmq_web_stomp"
    ];
    configItems = {
      # Consumer
      "consumer_timeout" = "28800000"; # 8h

      # TLS
      "listeners.tcp" = "none";
      "listeners.ssl.default" = "5671";
      "ssl_options.cacertfile" = "${
        config.security.acme.certs."messages.ofborg.org".directory
      }/chain.pem";
      "ssl_options.certfile" = "${config.security.acme.certs."messages.ofborg.org".directory}/cert.pem";
      "ssl_options.keyfile" = "${config.security.acme.certs."messages.ofborg.org".directory}/key.pem";
      "ssl_options.versions.1" = "tlsv1.3";

      # Auth
      "auth_mechanisms.1" = "PLAIN";
      "auth_mechanisms.2" = "AMQPLAIN";
      "anonymous_login_user" = "none";

      # Web interface
      "management.tcp.ip" = "::1";
      "management.tcp.port" = "15672";

      # Prometheus
      "cluster_name" = "messages.ofborg.org";
      "prometheus.tcp.ip" = "::1";

      # STOMP for ofborg-viewer
      "web_stomp.ssl.ip" = "::";
      "web_stomp.ssl.port" = "15673";
      "web_stomp.ssl.cacertfile" = "${
        config.security.acme.certs."messages.ofborg.org".directory
      }/chain.pem";
      "web_stomp.ssl.certfile" = "${config.security.acme.certs."messages.ofborg.org".directory}/cert.pem";
      "web_stomp.ssl.keyfile" = "${config.security.acme.certs."messages.ofborg.org".directory}/key.pem";
    };
  };

  # No need to reload RabbitMQ, this happens automatically every couple minutes
  security.acme.certs."messages.ofborg.org" = {
    webroot = "/var/lib/acme/acme-challenge";
    group = "rabbitmq";
  };

  systemd.services.rabbitmq = {
    stopIfChanged = false;
    requires = [ "acme-messages.ofborg.org.service" ];
    # https://github.com/rabbitmq/rabbitmq-server-release/issues/51
    serviceConfig.SuccessExitStatus = "69";
  };

  networking.firewall.allowedTCPPorts = [
    5671
    15673
  ];
}
