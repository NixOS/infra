# the content of this file should be put in the modules folder once the actual module has been upstreamed
{ config, pkgs, ... }:
{
  disabledModules = [ "services/web-apps/limesurvey.nix" ];

  imports = [ ../../modules/limesurvey.nix ];

  services.limesurvey = {
    enable = true;
    package = pkgs.limesurvey.overrideAttrs (old: {
      installPhase = old.installPhase + ''
        mkdir -p $out/share/limesurvey/upload/themes/survey/generalfiles/
        ln -s ${../../../survey/nixos-lores.png} $out/share/limesurvey/upload/themes/survey/generalfiles/
      '';
    });

    virtualHost = {
      serverName = "survey.staging.nixos.org";
      #adminAddr = "webmaster@nixos.org";
      enableACME = true;
      forceSSL = true;

    };

  };

}
