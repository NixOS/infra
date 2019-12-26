{
  channels = {
      # Channel name           https://hydra.nixos.org/job/<value>/latest-finished
      "nixos-unstable"       = "nixos/trunk-combined/tested";
      "nixos-unstable-small" = "nixos/unstable-small/tested";
      "nixpkgs-unstable"     = "nixpkgs/trunk/unstable";

      "nixos-19.09"          = "nixos/release-19.09/tested";
      "nixos-19.09-small"    = "nixos/release-19.09-small/tested";
      "nixpkgs-19.09-darwin" = "nixpkgs/nixpkgs-19.09-darwin/darwin-tested";

      "nixos-19.03"          = "nixos/release-19.03/tested";
      "nixos-19.03-small"    = "nixos/release-19.03-small/tested";
      "nixpkgs-19.03-darwin" = "nixpkgs/nixpkgs-19.03-darwin/darwin-tested";

      "nixos-18.09"          = "nixos/release-18.09/tested";
      "nixos-18.09-small"    = "nixos/release-18.09-small/tested";
      "nixpkgs-18.09-darwin" = "nixpkgs/nixpkgs-18.09-darwin/darwin-tested";
  };
}
