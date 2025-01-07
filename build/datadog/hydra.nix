{ pkgs, ... }:
{
  systemd.services.dd-agent.environment.PYTHONPATH =
    "${pkgs.pythonPackages.requests}/lib/python2.7/site-packages";
  environment.etc =
    let
      hydra-config = pkgs.writeText "hydra.yaml" ''
        init_config:

        instances:
          - check: 1
      '';
    in
    [
      {
        source = hydra-config;
        target = "dd-agent/conf.d/hydra.yaml";
      }
      {
        source = ./hydra.py;
        target = "dd-agent/checks.d/hydra.py";
      }
    ];
}
