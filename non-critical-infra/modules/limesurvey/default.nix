{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../nginx.nix
  ];

  services.limesurvey = {
    enable = true;
    package = pkgs.limesurvey.overrideAttrs (oldAttrs: {
      installPhase = oldAttrs.installPhase + ''
        mkdir -p $out/share/limesurvey/upload/themes/survey/generalfiles/
        ln -s ${./nixos-lores.png} $out/share/limesurvey/upload/themes/survey/generalfiles/
      '';
    });
    virtualHost = {
      # unused
      hostName = "survey-test.nixos.org";
      adminAddr = "webmaster@nixos.org";
    };
  };

  services.httpd.enable = lib.mkForce false;

  # https://manual.limesurvey.org/General_FAQ#With_nginx_webserver
  services.nginx.virtualHosts."survey-test.nixos.org" = {
    enableACME = true;
    forceSSL = true;
    root = "${config.services.limesurvey.package}/share/limesurvey";
    locations."~ \.php$" = {
      extraConfig = ''
        fastcgi_split_path_info  ^(.+\.php)(.*)$;
        try_files $uri index.php;
        fastcgi_pass unix:${config.services.phpfpm.pools.limesurvey.socket};
        fastcgi_index index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        fastcgi_param  SCRIPT_NAME      $fastcgi_script_name;
      '';
    };
    extraConfig = ''
      try_files $uri /index.php?$uri&$args;

      # Disallow reading inside php script directory, see issue with debug > 1 on note
      location ~ ^/(application|docs|framework|locale|protected|tests|themes/\w+/views) {
          deny  all;
      }
      # Disallow reading inside runtime directory
      location ~ ^/tmp/runtime/ {
          deny  all;
      }

      # Allow access to well-known directory, different usage, for example ACME Challenge for Let's Encrypt
      location ~ /\.well-known {
          allow all;
      }
      # Deny all attempts to access hidden files
      # such as .htaccess, .htpasswd, .DS_Store (Mac).
          location ~ /\. {
          deny all;
      }
      #Disallow direct read user upload files
      location ~ ^/upload/surveys/.*/fu_[a-z0-9]*$ {
          return 444;
      }
      #Disallow uploaded potential executable files in upload directory
      location ~* /upload/.*\.(pl|cgi|py|pyc|pyo|phtml|sh|lua|php|php3|php4|php5|php6|pcgi|pcgi3|pcgi4|pcgi5|pcgi6|icn)$ {
          return 444;
      }
      #avoid processing of calls to unexisting static files by yii
      location ~ \.(js|css|png|jpg|gif|swf|ico|pdf|mov|fla|zip|rar)$ {
          try_files $uri =404;
      }
    '';
  };

  users.users.limesurvey.group = lib.mkForce "limesurvey";
  users.groups.limesurvey = {};

  systemd.services.limesurvey-init.serviceConfig = {
    Group = lib.mkForce "limesurvey";
  };

  services.phpfpm.pools.limesurvey = {
    group = lib.mkForce "limesurvey";
    settings = {
      "listen.owner" = lib.mkForce "nginx";
      "listen.group" = lib.mkForce "nginx";
    };
  };
}
