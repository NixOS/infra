{ config, lib, ... }:
let
  nodes = {
    ofborg-eval02 = {
      substituter = "eval02.ofborg.org";
      public-key = "eval02.ofborg.org:85vbhZviIv2eeC3VKK2T/X/zzgIYLYjyGw3Pi+Pqh34=";
    };
    ofborg-eval03 = {
      substituter = "eval03.ofborg.org";
      public-key = "eval03.ofborg.org:HATIHUe6QMH83dbDpnUv9VeuaNDBjeWshW2monmRK1c=";
    };
    ofborg-eval04 = {
      substituter = "eval04.ofborg.org";
      public-key = "eval04.ofborg.org:k4s/u1JWDew+dwXcuFvAAVFK2DfN6ib+73iCwX5gkBE=";
    };
    ofborg-build01 = {
      substituter = "build01.ofborg.org";
      public-key = "build01.ofborg.org:Edgo6+RgHXa8nlxuLAgh18fMhQuXGdXNcYK6yNKQaQ8=";
    };
    ofborg-build02 = {
      substituter = "build02.ofborg.org";
      public-key = "build02.ofborg.org:uw5IBpYv129c8+ltrQ288TGvmE5JqNZA+q7GW3tDaUk=";
    };
    ofborg-build03 = {
      substituter = "build03.ofborg.org";
      public-key = "build03.ofborg.org:8LFTt2s1cbzniV4MLkT30qEHPY0cK3RP+6fk03GD3lw=";
    };
    ofborg-build04 = {
      substituter = "build04.ofborg.org";
      public-key = "build04.ofborg.org:NHEGj8moimu2TiZNIA4DOb4kVhvds6Vlzr2TAwX1mUY=";
    };
    ofborg-build05 = {
      substituter = "build05.ofborg.org";
      public-key = "build05.ofborg.org:RPuXIkyo86mCmsfYqyK/STIbPE+DM9Ixcw7HUe64Ss4=";
    };
  };
  ownNode = nodes."${config.networking.hostName}";
  allOtherNodes = lib.filterAttrs (n: _: n != config.networking.hostName) nodes;
in
{
  services.harmonia = {
    enable = true;
    signKeyPaths = [ "/run/secrets/harmonia/secret" ];
    settings = {
      priority = 50;
    };
  };

  nix.settings = {
    fallback = true;
    extra-substituters = lib.mapAttrsToList (_: config: "http://${config.substituter}") allOtherNodes;
    extra-trusted-public-keys = lib.mapAttrsToList (_: config: config.public-key) allOtherNodes;
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    virtualHosts."${ownNode.substituter}" = {
      locations."/".extraConfig = ''
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_redirect http:// https://;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
      '';
    };
  };
}
