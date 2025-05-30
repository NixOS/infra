{
  imports = [
    ../nginx.nix
  ];

  services.nixseparatedebuginfod.enable = true;

  services.nginx.virtualHosts."debuginfod.nixos.org" = {
    enableACME = true;
    forceSSL = true;

    locations."= /" = { };

    locations."= /index.html" = {
      alias = ./index.html;
    };

    locations."/" = {
      proxyPass = "http://127.0.0.1:1949";
      index = "index.html";
    };
  };
}
