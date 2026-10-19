# Origin for per-file reads under `cache.nixos.org/nix/store/`.
#
# nar-serve answers `GET /nix/store/<hash>/<path>` from the store path's NAR on
# `cache.nixos.org`: it decompresses forward to the wanted file and emits only
# that file's bytes. Directories, absent paths and `HEAD` requests come from the
# `.ls` listing, without the NAR. It holds no credentials, needs no bucket access
# and has no write path.
#
# Access is only for the clients in `clients`, each with its own token. Fastly
# and this host both make sure that a request has the
# `Authorization: Bearer <token>` header of a client. Fastly compares the
# SHA-256 of the token, which is in `terraform/cache.tf`. This host compares the
# token itself and writes the name of the client to the access log.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.nar-serve;
  upstreamPort = 8384;

  # The token of each client is in `secrets/nar-serve-token-<client>.caliban`.
  clients = [ "nixos-search" ];
  secretName = client: "nar-serve-token-${client}";
in
{
  # `nixos-26.05` has nar-serve 0.7.0: it reads the full NAR for each request
  # and has no `maxConcurrency` or `metricsAddress`. Use the module and package
  # from unstable, which have 0.9.0.
  disabledModules = [ "services/networking/nar-serve.nix" ];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/nar-serve.nix"
    ./nginx.nix
  ];

  services.nar-serve = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.nar-serve;
    # Decompressing the archive up to the wanted file is the entire server-side
    # cost of a request, so this is what bounds CPU use. This host runs other
    # services, so the endpoint does not get every core.
    maxConcurrency = 4;
    metricsAddress = "[::]:9464";
    cacheURL = "http://127.0.0.1:${toString upstreamPort}/";
  };

  networking.firewall.extraInputRules = ''
    ip6 saddr $prometheus_inet6 tcp dport 9464 accept
    ip saddr $prometheus_inet4 tcp dport 9464 accept
  '';

  # To add a client, or to replace the token of a client:
  #
  #   $ cd non-critical-infra
  #   $ SECRET_PATH=secrets/nar-serve-token-<client>.caliban
  #   $ openssl rand -hex 32 | tr -d '\n' > "$SECRET_PATH"
  #   $ sha256sum "$SECRET_PATH"  # put this in `nar_serve_token_sha256`
  #   $ sops encrypt --in-place "$SECRET_PATH"
  sops.secrets = lib.genAttrs (map secretName clients) (name: {
    sopsFile = ../secrets + "/${name}.caliban";
    format = "binary";
  });

  sops.templates."nar-serve-tokens.map" = {
    content = lib.concatMapStrings (client: ''
      "${config.sops.placeholder.${secretName client}}" ${client};
    '') clients;
    owner = config.services.nginx.user;
    reloadUnits = [ config.systemd.services.nginx.name ];
  };

  # The 64 characters of the token do not fit in a bucket of the default size.
  services.nginx.mapHashBucketSize = 128;

  # The scheme name is not case-sensitive (RFC 9110).
  services.nginx.appendHttpConfig = ''
    map $http_authorization $nar_serve_token {
      default "";
      "~*^bearer (.+)$" $1;
    }

    map $nar_serve_token $nar_serve_client {
      default "";
      include ${config.sops.templates."nar-serve-tokens.map".path};
    }

    # `combined`, with the client in place of the user of Basic authentication.
    log_format nar_serve '$remote_addr - $nar_serve_client [$time_local] '
                         '"$request" $status $body_bytes_sent '
                         '"$http_referer" "$http_user_agent"';
  '';

  services.nginx.virtualHosts."nar-serve.nixos.org" = {
    forceSSL = true;
    enableACME = true;

    extraConfig = ''
      access_log /var/log/nginx/access.log nar_serve;
    '';

    # Fastly does not keep a 401, thus a token that is not correct here does not
    # put errors in its cache. A 401 must tell the client which authentication
    # scheme to use (RFC 9110).
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString cfg.port}";
      extraConfig = ''
        if ($nar_serve_client = "") {
          add_header WWW-Authenticate Bearer always;
          return 401;
        }
      '';
    };
  };

  services.nginx.proxyCachePath.nar-serve = {
    enable = true;
    keysZoneName = "nar-serve";
    # The files of a store path come in one burst, thus the cache must keep a
    # NAR for minutes, not days. Fastly keeps the responses of nar-serve.
    inactive = "1h";
    maxSize = "5g";
  };

  services.nginx.virtualHosts."nar-serve-upstream" =
    let
      # A `proxy_set_header` in a location replaces all inherited ones, thus
      # `recommendedProxySettings` must be off and `Host` must be set here.
      # Fastly gives `421 Misdirected Request` for a different `Host`.
      upstream = ''
        proxy_set_header Host cache.nixos.org;
        proxy_ssl_server_name on;
        proxy_ssl_verify on;
        proxy_ssl_verify_depth 2;
        proxy_ssl_trusted_certificate /etc/ssl/certs/ca-certificates.crt;
      '';
    in
    {
      listen = [
        {
          addr = "127.0.0.1";
          port = upstreamPort;
        }
      ];

      # `.narinfo` and `.ls` are small, and a 404 must not stay in the cache.
      locations."/" = {
        proxyPass = "https://cache.nixos.org";
        recommendedProxySettings = false;
        extraConfig = upstream;
      };

      # When nar-serve closes the connection after the wanted file, nginx
      # continues to read and keeps the full NAR. Over 40 store paths with 2 or
      # 3 files each, this halves the bytes from `cache.nixos.org`. A path with
      # one file costs a full NAR, not the prefix up to the file.
      #
      # With `proxy_cache_lock`, parallel requests for one NAR wait for a single
      # download, not start one each.
      locations."/nar/" = {
        proxyPass = "https://cache.nixos.org";
        recommendedProxySettings = false;
        extraConfig = upstream + ''
          proxy_cache nar-serve;
          proxy_cache_valid 200 1h;
          proxy_cache_lock on;
        '';
      };
    };
}
