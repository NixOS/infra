# Origin for per-file reads under `cache.nixos.org/nix/store/`.
#
# nar-serve answers `GET /nix/store/<hash>/<path>` from the store path's NAR on
# `cache.nixos.org`: it decompresses forward to the wanted file and emits only
# that file's bytes. Directories, absent paths and `HEAD` requests come from the
# `.ls` listing, without the NAR. It holds no credentials, needs no bucket access
# and has no write path, so it is exactly as trusted as the `.ls` listings.
{
  config,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.services.nar-serve;
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
  };

  networking.firewall.extraInputRules = ''
    ip6 saddr $prometheus_inet6 tcp dport 9464 accept
    ip saddr $prometheus_inet4 tcp dport 9464 accept
  '';

  services.nginx.virtualHosts."nar-serve.nixos.org" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString cfg.port}";
    };
  };
}
