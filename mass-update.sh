#! /bin/sh

export SSH_AUTH_SOCK= # hack

for i in localhost jimmy timmy terrance phillip "localhost -p 2222"; do
    echo "=== Updating $i ==="
    ssh -i /root/.ssh/id_mass_update root@$i sh --login -c '"cd /etc/nixos && svn up nixos nixpkgs configurations release && nixos-rebuild switch"'
done
