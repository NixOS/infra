# nixos.org hardware configuration

This repository contains all the hardware configuration for the nixos project
infrastructure.

Amongs other things it contains configuration for:

* nixos.org
* cache.nixos.org
* hydra.nixos.org and all the build machines
* releases.nixos.org
* tarballs.nixos.org

Most of the infrastructure is currently managed using NixOps. Some if it is
managed using Terraform.

## Team

This is currently the list of people part of the @NixOS/nixos-infra team:

* @AmineChikhaoui
* @edolstra
* @grahamc
* @rbvermaa
* @zimbatm

The responsability of the team is to provide infrastructure for the Nix and
NixOS community.

All the members should be watching this repository for changes.

## Reporting issues

If you experience any issues with the infrastructure, please [post a new issue
to this repository][1].

[1]: https://github.com/NixOS/nixos-org-configurations/issues/new
