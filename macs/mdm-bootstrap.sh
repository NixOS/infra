#! /usr/bin/env bash

# MDM Bootstrap script for nix-darwin Mac builders
#
# This script is intended to be run by an MDM solution (e.g. Mosyle)
# during initial machine bootstrap, after building the nix-darwin
# configuration into a ./result symlink.
#
# It replaces the deprecated activate-user step with the recommended
# darwin-rebuild activate approach.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "$0: please run this script as root"
  exit 1
fi

if [[ ! -e ./result ]]; then
  echo "$0: no ./result symlink found. Build your nix-darwin configuration first."
  exit 1
fi

systemConfig="$(readlink -f ./result)"

if [[ ! -d "$systemConfig" ]]; then
  echo "$0: $systemConfig does not exist or is not a directory"
  exit 1
fi

nix-env -p /nix/var/nix/profiles/system --set "$systemConfig"

if [[ -x "$systemConfig/sw/bin/darwin-rebuild" ]]; then
  echo "Activating system via darwin-rebuild activate..."
  "$systemConfig/sw/bin/darwin-rebuild" activate
else
  echo "darwin-rebuild not found; falling back to legacy activation."
  if [[ -x "$systemConfig/activate-user" ]]; then
    echo "WARNING: activate-user is deprecated and will be removed in nix-darwin 25.11."
    "$systemConfig/activate-user"
  fi
  "$systemConfig/activate"
fi
