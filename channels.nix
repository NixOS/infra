rec {
  channels = {
    # "Channel name" = {
    #   # This should be the <value> part of
    #   # https://hydra.nixos.org/job/<value>/latest-finished
    #   job = "project/jobset/jobname";
    #
    #   # When adding a new version, determine if it needs to be tagged as a
    #   # variant -- for example:
    #   # nixos-xx.xx         => primary
    #   # nixos-xx.xx-small   => small
    #   # nixos-xx.xx-darwin  => darwin
    #   # nixos-xx.xx-aarch64 => aarch64
    #   variant = "primary";
    #
    #   # Channel Status:
    #   # '*-unstable' channels are always "rolling"
    #   # Otherwise a release generally progresses through the following phases:
    #   #
    #   #  - Directly after branch off                   => "beta"
    #   #  - Once the channel is released                => "stable"
    #   #  - Once the next channel is released           => "deprecated"
    #   #  - N months after the next channel is released => "unmaintained"
    #   #    (check the release notes for when this should happen)
    #   status = "beta";
    # };
    "nixos-unstable" = {
      job = "nixos/unstable/tested";
      variant = "primary";
      status = "rolling";
    };
    "nixos-unstable-small" = {
      job = "nixos/unstable-small/tested";
      variant = "small";
      status = "rolling";
    };
    "nixpkgs-unstable" = {
      job = "nixpkgs/unstable/unstable";
      variant = "primary";
      status = "rolling";
    };

    "nixos-25.11" = {
      job = "nixos/release-25.11/tested";
      variant = "primary";
      status = "stable";
    };
    "nixos-25.11-small" = {
      job = "nixos/release-25.11-small/tested";
      variant = "small";
      status = "stable";
    };
    "nixpkgs-25.11-darwin" = {
      job = "nixpkgs/nixpkgs-25.11-darwin/darwin-tested";
      variant = "darwin";
      status = "stable";
    };

    "nixos-25.05" = {
      job = "nixos/release-25.05/tested";
      variant = "primary";
      status = "deprecated";
    };
    "nixos-25.05-small" = {
      job = "nixos/release-25.05-small/tested";
      variant = "small";
      status = "deprecated";
    };
    "nixpkgs-25.05-darwin" = {
      job = "nixpkgs/nixpkgs-25.05-darwin/darwin-tested";
      variant = "darwin";
      status = "deprecated";
    };
  };

  channels-with-urls = builtins.mapAttrs (_name: about: about.job) channels;
}
