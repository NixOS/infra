{ inputs, ... }:
{
  imports = [
    inputs.first-time-contribution-tagger.nixosModule
  ];

  services.first-time-contribution-tagger = {
    enable = true;
    interval = "*:0/10";
    environment = {
      FIRST_TIME_CONTRIBUTION_LABEL = "12. first-time contribution";
      FIRST_TIME_CONTRIBUTION_CACHE = "/var/lib/first-time-contribution-tagger/cache";
      FIRST_TIME_CONTRIBUTION_REPO = "nixpkgs";
      FIRST_TIME_CONTRIBUTION_ORG = "NixOS";
    };
    environmentFile = "/root/first-time-contribution-tagger.env";
  };

  sops.secrets.first-time-contribution-tagger-env = {
    sopsFile = ../secrets/first-time-contribution-tagger-env.caliban;
    format = "binary";
    path = "/root/first-time-contribution-tagger.env";
  };
}
