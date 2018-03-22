#!/bin/sh

set -eux

drv=$(nix-instantiate ./build.nix -A system --show-trace)
outpath=$(nix-store -q --outputs "${drv}" | head -n1)

for macId in `seq 1 9`; do
    host="mac$macId"

    if ! ssh $host test -f "$drv"; then
        echo "Copying derivation to $host"

        nix-copy-closure --to $host "$drv"
    else
        echo "Derivation already exists on $host"
    fi

    if ! ssh $host test -d "$outpath"; then
        echo "Building derivation to $host"
        while ! ssh $host NIX_REMOTE=daemon /nix/var/nix/profiles/default/bin/nix-store -r "$drv" -j 1; do
            echo "retrying..."
            sleep 1
        done
    else
        echo "Build path already exists on $host"
    fi

    if [ "$(ssh -t $host readlink /run/current-system)" == "$outpath"$'\r' ]; then
        echo "Already deployed to $host"
    else
        echo "Activating on $host"
        ssh -t $host NIX_REMOTE=daemon sudo "$outpath/activate"
        # ssh $host NIX_REMOTE=daemon "$outpath/activate-user"
    fi
done
