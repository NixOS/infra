# The NixOS infrastructure configurations

This repository contains all the hardware configuration for the nixos project
infrastructure.

All the hosts are currently managed using NixOps. Some of the infrastructure
is managed using Terraform. There are still a lot of things configured
manually.

## Docs

* [Resources inventory](docs/inventory.md)

## Team

There are two teams managing this repository. The responsibility of both teams
is to provide infrastructure for the Nix and NixOS community.

### [@NixOS/infra-build](https://github.com/orgs/NixOS/teams/infra-build)

This team has access to all the infrastructure, including the build
infrastructure. The members are a subset of the next team.

### [@NixOS/infra](https://github.com/orgs/NixOS/teams/infra)

First level responders. This team helps with the high-level infrastructure.

All the members should be watching this repository for changes.

## Reporting issues

If you experience any issues with the infrastructure, please [post a new issue
to this repository][1].

[1]: https://github.com/NixOS/nixos-org-configurations/issues/new
