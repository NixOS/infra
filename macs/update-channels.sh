#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-git

nix-prefetch-git https://github.com/nixos/nixpkgs-channels.git \
                 --rev "refs/heads/nixos-18.03" > ./nix/nixpkgs.json

nix-prefetch-git https://github.com/lnl7/nix-darwin.git \
                 --rev "refs/heads/master" > ./nix/nix-darwin.json
