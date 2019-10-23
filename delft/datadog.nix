{
  services.dd-agent.enable = true;
  services.dd-agent.api_key = builtins.readFile /home/deploy/src/nixos-org-configurations/delft/datadog.secret;
}
