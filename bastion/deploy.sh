#!/usr/bin/env bash
#
# Temporary deploy script to work around NixOps.
#
nixos-rebuild \
  --flake ".#bastion" \
  --target-host bastion.nixos.org \
  --use-remote-sudo \
  "$@"
