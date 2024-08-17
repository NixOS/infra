# the content of this file should be put in the modules folder once the actual module has been upstreamed
# PR: https://github.com/NixOS/nixpkgs/pull/325665/
{ config, ... }:
{
  disabledModules = [ "services/web-apps/limesurvey.nix" ];

  imports = [ ../../modules/limesurvey.nix ];

  services.limesurvey = {
    enable = true;
    encryptionKeyFile = config.sops.secrets.limesurvey-encryption-key.path;
    encryptionNonceFile = config.sops.secrets.limesurvey-encryption-nonce.path;
    virtualHost = {
      serverName = "survey.nixos.org";
      enableACME = true;
      forceSSL = true;
    };
  };

  sops.secrets.limesurvey-encryption-key = {
    format = "binary";
    sopsFile = ../../secrets/limesurvey-encryption-key.caliban;
  };

  sops.secrets.limesurvey-encryption-nonce = {
    format = "binary";
    sopsFile = ../../secrets/limesurvey-encryption-nonce.caliban;
  };


}
