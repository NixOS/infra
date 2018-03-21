#!/bin/sh

set -eux

drv=$(nix-instantiate ./build.nix -A system --show-trace)
outpath=$(nix-store -q --outputs "${drv}" | head -n1)

for macId in `seq 1 9`; do
    host="mac$macId"
    SSHOPTS="$host"

    if ! ssh $SSHOPTS test -f "$drv"; then
        echo "Copying derivation to $host"

        # A lame version of nix-copy-closure since we can't SSH directly in
        # as a trusted user
        nix-store --export $(nix-store -qR "$drv") | gzip -c | ssh $SSHOPTS /bin/sh -c '"cat > closure"'
        ssh -t $SSHOPTS sudo /bin/sh -c '"cat closure | gzip -d | /nix/var/nix/profiles/default/bin/nix-store --import"'
    else
        echo "Derivation already exists on $host"
    fi

    if ! ssh $SSHOPTS test -d "$outpath"; then
        echo "Building derivation to $host"
        while ! ssh $SSHOPTS NIX_REMOTE=daemon /nix/var/nix/profiles/default/bin/nix-store -r "$drv" -j 1; do
            echo "retrying..."
            sleep 1
        done
    else
        echo "Build path already exists on $host"
    fi

    if [ "$(ssh -t $SSHOPTS readlink /run/current-system)" == "$outpath"$'\r' ]; then
        echo "Already deployed to $host"
    else
        echo "Activating on $host"
        ssh -t $SSHOPTS NIX_REMOTE=daemon sudo "$outpath/activate"
        # ssh $SSHOPTS NIX_REMOTE=daemon "$outpath/activate-user"
    fi
done
