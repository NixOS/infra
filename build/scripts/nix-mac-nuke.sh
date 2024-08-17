#! /usr/bin/env bash

service_plist=/Library/LaunchDaemons/org.nixos.nix-daemon.plist

launchctl stop $service_plist
launchctl unload $service_plist

dscl . -delete /Groups/nixbld

for i in $(seq 1 20); do
  dscl . -delete /Users/nixbld$i
done

sudo rm -f $service_plist

sudo rm -rf /nix /etc/nix/nix.conf

rm -f $HOME/.nix-channels $HOME/.nix-profile
rm -rf $HOME/.nix-defexpr
