{
  sops.secrets = {
    "ofborg/github-oauth-secret" = {
      mode = "0440";
      group = "ofborg-github-oauth-secret";
      sopsFile = ../../secrets/github-tokens.ofborg.org.yml;
    };
    "ofborg/github-app-key" = {
      mode = "0440";
      group = "ofborg-github-app-key";
      sopsFile = ../../secrets/github-tokens.ofborg.org.yml;
    };
  };
  users.groups."ofborg-github-oauth-secret" = { };
  users.groups."ofborg-github-app-key" = { };
}
