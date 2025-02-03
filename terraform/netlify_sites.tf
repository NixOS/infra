# This file contains all of the websites that we host using Netlify.

resource "netlify_deploy_key" "key" {}

resource "netlify_site" "nix-dev" {
  name          = "nix-dev"
  custom_domain = "nix.dev"

  repo {
    provider    = "github"
    repo_path   = "NixOS/nix.dev"
    repo_branch = "master"
  }
}

resource "netlify_site" "nixos-common-styles" {
  name          = "nixos-common-styles"
  custom_domain = "common-styles.nixos.org"

  repo {
    provider    = "github"
    repo_path   = "NixOS/nixos-common-styles"
    repo_branch = "main"
  }
}

resource "netlify_site" "nixos-status" {
  name          = "nixos-status"
  custom_domain = "status.nixos.org"

  repo {
    provider    = "github"
    repo_path   = "NixOS/nixos-status"
    repo_branch = "main"
  }
}

resource "netlify_site" "nixos-planet" {
  name          = "nixos-planet"
  custom_domain = "planet.nixos.org"

  repo {
    provider    = "github"
    repo_path   = "NixOS/nixos-planet"
    repo_branch = "master"
  }
}

resource "netlify_site" "nixos-search" {
  name          = "nixos-search"
  custom_domain = "search.nixos.org"

  repo {
    provider    = "github"
    repo_path   = "NixOS/nixos-search"
    repo_branch = "master"
  }
}

resource "netlify_site" "nixos-homepage" {
  name          = "nixos-homepage"
  custom_domain = "nixos.org"

  repo {
    deploy_key_id = netlify_deploy_key.key.id
    provider      = "github"
    repo_path     = "NixOS/nixos-homepage"
    repo_branch   = "master"
  }
}
