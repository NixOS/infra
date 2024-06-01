{ config, pkgs, ... }:

{
  sops.secrets.opendkim-private-key = {
    sopsFile = ../secrets/opendkim-private-key.caliban;
    format = "binary";
    owner = config.services.postfix.user;
  };
  services.opendkim = {
    enable = true;
    domains = config.networking.fqdn;
    selector = "mail";
    user = config.services.postfix.user;
    group = config.services.postfix.group;
    keyPath = "/run/opendkim-keys";
  };

  systemd.services.opendkim.serviceConfig = {
    ExecStartPre = [
      (
        "+${pkgs.writeShellScript "opendkim-keys" ''
          install -o ${config.services.postfix.user} -g ${config.services.postfix.group} -D -m0700 ${config.sops.secrets.opendkim-private-key.path} /run/opendkim-keys/${config.services.opendkim.selector}.private
        ''}"
      )
    ];
  };

  services.postfix = {
    enable = true;
    hostname = config.networking.fqdn;
    domain = config.networking.fqdn;
    config = {
      smtp_tls_note_starttls_offer = "yes";
      smtp_tls_security_level = "may";
      tls_medium_cipherlist = "AES128+EECDH:AES128+EDH";
      smtpd_relay_restrictions = "permit_mynetworks permit_sasl_authenticated defer_unauth_destination";
      mydestination = "localhost.$mydomain, localhost, $myhostname";
      myorigin = "$mydomain";
      milter_default_action = "accept";
      milter_protocol = "6";
      smtpd_milters = "unix:/run/opendkim/opendkim.sock";
      non_smtpd_milters = "unix:/run/opendkim/opendkim.sock";
      inet_interfaces = "loopback-only";
      inet_protocols = "all";
    };
  };

}
