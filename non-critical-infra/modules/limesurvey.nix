{
  config,
  ...
}:
{
  services.limesurvey = {
    enable = true;
    encryptionKeyFile = config.sops.secrets.limesurvey-encryption-key.path;
    encryptionNonceFile = config.sops.secrets.limesurvey-encryption-nonce.path;
    webserver = "nginx";
    nginx.virtualHost = {
      serverName = "survey.nixos.org";
      enableACME = true;
      forceSSL = true;
    };
  };

  sops.secrets.limesurvey-encryption-key = {
    format = "binary";
    sopsFile = ../secrets/limesurvey-encryption-key.caliban;
  };

  sops.secrets.limesurvey-encryption-nonce = {
    format = "binary";
    sopsFile = ../secrets/limesurvey-encryption-nonce.caliban;
  };

}
