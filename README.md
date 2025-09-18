# The NixOS infrastructure configurations

This repository contains all the hardware configuration for the nixos project
infrastructure.

All the hosts are currently managed using NixOps. Some of the infrastructure is
managed using Terraform. There are still a lot of things configured manually.

## Docs

- [Resources inventory](docs/inventory.md)

## Team

There are two teams managing this repository. The responsibility of both teams
is to provide infrastructure for the Nix and NixOS community.

### [@NixOS/infra-build](https://github.com/orgs/NixOS/teams/infra-build)

This team has access to all the infrastructure, including the build
infrastructure. The members are a subset of the next team.

### [@NixOS/infra](https://github.com/orgs/NixOS/teams/infra)

First level responders. This team helps with the high-level infrastructure.

All the members should be watching this repository for changes.

## Regular catch up

We meet regularly over Jitsi to hash some issues out. Sometimes it helps to have
dedicated focus and higher communication bandwidth.

There is an open team meeting **every other Thursday at
[18:00 (Europe/Zurich)](https://dateful.com/convert/zurich?t=18)**. See the
[google calendar](https://calendar.google.com/calendar/u/0/embed?src=b9o52fobqjak8oq8lfkhg3t0qg@group.calendar.google.com)
(search for "NixOS Infra") to see the next date.

Location: <https://meet.cccda.de/nix-osin-fra> Meeting notes:
<https://pad.lassul.us/nixos-infra>

## Reporting issues

If you experience any issues with the infrastructure, please
[post a new issue to this repository][1].

[1]: https://github.com/NixOS/infra/issues/new
