rec {
  channels = {
      # "Channel name" = {
      #   job = "project/jobset/jobname"; like https://hydra.nixos.org/job/<value>/latest-finished
      #   # when adding a new version, mark the oldest as "not current". New releases should always be current.
      #   # Channels where `current = false` are marked `end-of-life` on https://status.nixos.org/ and alerting is disabled.
      #   current = true;
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

      "nixos-21.05" = {
        job = "nixos/release-21.05/tested";
        current = true;
      };
      "nixos-21.05-small" = {
        job = "nixos/release-21.05-small/tested";
        current = true;
      };
      "nixpkgs-21.05-darwin" = {
        job = "nixpkgs/nixpkgs-21.05-darwin/darwin-tested";
        current = true;
      };
      "nixos-21.05-aarch64" = {
        job = "nixos/release-21.05-aarch64/tested";
        current = true;
      };

      "nixos-20.09" = {
        job = "nixos/release-20.09/tested";
        current = true;
      };
      "nixos-20.09-small" = {
        job = "nixos/release-20.09-small/tested";
        current = true;
      };
      "nixpkgs-20.09-darwin" = {
        job = "nixpkgs/nixpkgs-20.09-darwin/darwin-tested";
        current = true;
      };
      "nixos-20.09-aarch64" = {
        job = "nixos/release-20.09-aarch64/tested";
        current = true;
      };

      "nixos-20.03" = {
        job = "nixos/release-20.03/tested";
        current = false;
      };
      "nixos-20.03-small" = {
        job = "nixos/release-20.03-small/tested";
        current = false;
      };
      "nixpkgs-20.03-darwin" = {
        job = "nixpkgs/nixpkgs-20.03-darwin/darwin-tested";
        current = false;
      };

      "nixos-19.09" = {
        job = "nixos/release-19.09/tested";
        current = false;
      };
      "nixos-19.09-small" = {
        job = "nixos/release-19.09-small/tested";
        current = false;
      };
      "nixpkgs-19.09-darwin" = {
        job = "nixpkgs/nixpkgs-19.09-darwin/darwin-tested";
        current = false;
      };
  };

  channels-with-urls = (builtins.mapAttrs (name: about: about.job) channels);
}
