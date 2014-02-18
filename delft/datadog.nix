{
  services.dd-agent.enable = true;
  services.dd-agent.api_key = builtins.readFile ./datadog.secret;
}
