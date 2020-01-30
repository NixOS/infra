rec {
  channels = {
      # "Channel name" = {
      #   job = "project/jobset/jobname"; like https://hydra.nixos.org/job/<value>/latest-finished
      #   current = true; # when adding a new version, mark the oldest as "not current"
      # };
      "nixos-unstable" = {
        job = "nixos/trunk-combined/tested";
        current = true;
      };
      "nixos-unstable-small" = {
        job = "nixos/unstable-small/tested";
        current = true;
      };
      "nixpkgs-unstable" = {
        job = "nixpkgs/trunk/unstable";
        current = true;
      };

      "nixos-19.09" = {
        job = "nixos/release-19.09/tested";
        current = true;
      };
      "nixos-19.09-small" = {
        job = "nixos/release-19.09-small/tested";
        current = true;
      };
      "nixpkgs-19.09-darwin" = {
        job = "nixpkgs/nixpkgs-19.09-darwin/darwin-tested";
        current = true;
      };

      "nixos-19.03" = {
        job = "nixos/release-19.03/tested";
        current = false;
      };
      "nixos-19.03-small" = {
        job = "nixos/release-19.03-small/tested";
        current = false;
      };
      "nixpkgs-19.03-darwin" = {
        job = "nixpkgs/nixpkgs-19.03-darwin/darwin-tested";
        current = false;
      };
  };

  channels-with-urls = (builtins.mapAttrs (name: about: about.job) channels);
}
