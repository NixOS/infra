{ options, ... }:

let
  port = 3001;

  # re: https://community.letsencrypt.org/t/production-chain-changes/150739/1
  # re: https://github.com/ipxe/ipxe/pull/116
  # re: https://github.com/ipxe/ipxe/pull/112
  # re: https://lists.ipxe.org/pipermail/ipxe-devel/2020-May/007042.html
  legoFlags = [ "--preferred-chain" "ISRG Root X1" ];
in {
  services.nix-netboot-serve = {
    enable = true;
    listen = "127.0.0.1:${toString port}";
  };

  security.acme = {
    # These cert parameters are very specifically & carefully chosen for iPXE compatibility.
    certs."netboot.nixos.org" = {
      keyType = "rsa4096";
      extraLegoRunFlags = legoFlags;
      extraLegoRenewFlags = legoFlags;
    };
  };

  services.nginx = {
    enable = true;

    sslProtocols = "TLSv1.2 TLSv1.3"; # iPXE only supports TLSv1.2
    sslCiphers = options.services.nginx.sslCiphers.default + ":AES256-SHA256"; # iPXE needs AES256-SHA256

    virtualHosts."netboot.nixos.org" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:${toString port}/";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
