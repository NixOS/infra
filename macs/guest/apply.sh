#!/usr/bin/env bash

echo "apply started at $(date)" | nc -w0 -u 10.172.170.1 1514

printf '\n*.*\t@10.172.170.1:1514\n' | tee -a /etc/syslog.conf
pkill syslog
pkill asl

exec 3>&1
exec 2> >(nc -u 10.172.170.1 1514)
exec 1>&2

PS4='${BASH_SOURCE}::${FUNCNAME[0]}::$LINENO '
set -o pipefail
set -ex
date

function finish {
    set +e
    cd /
    sleep 1
    umount -f /Volumes/CONFIG
}
trap finish EXIT

cat <<EOF | tee -a /etc/ssh/sshd_config
PermitRootLogin prohibit-password
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
EOF

launchctl stop com.openssh.sshd
launchctl start com.openssh.sshd


cd /Volumes/CONFIG

cp -r ./etc/ssh/ssh_host_* /etc/ssh
chown root:wheel /etc/ssh/ssh_host_*
chmod 600 /etc/ssh/ssh_host_*
cd /

echo "%admin ALL = NOPASSWD: ALL" | tee /etc/sudoers.d/passwordless

(
    # Make this thing work as root
    export USER=root
    export HOME=~root
    export ALLOW_PREEXISTING_INSTALLATION=1
    env

    sudo -i -H -u nixos -- sh /Volumes/CONFIG/install --daemon < /dev/null
)

(
    # Make this thing work as root
    export USER=root
    export HOME=~root

    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    env
    ls -la /private || true
    ls -la /private/var || true
    ls -la /private/var/run || true
    ln -s /private/var/run /run || true

    # todo: clean up this channel business, which is complicated because
    # channels on darwin are a bit ill defined and have a very bad UX.
    # If me, Graham, the author of the multi-user darwin installer can't
    # even figure this out, how can I possibly expect anybody else to know.
    nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
    nix-channel --add https://nixos.org/channels/nixpkgs-20.09-darwin nixpkgs
    nix-channel --update

    sudo -i -H -u nixos -- nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
    sudo -i -H -u nixos -- nix-channel --add https://nixos.org/channels/nixpkgs-20.09-darwin nixpkgs
    sudo -i -H -u nixos -- nix-channel --update

    export NIX_PATH=$NIX_PATH:darwin=https://github.com/LnL7/nix-darwin/archive/master.tar.gz

    installer=$(nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer --no-out-link)
    set +e
    yes | sudo -i -H -u nixos -- $installer/bin/darwin-installer;
    echo $?
    set -e
)

(
    export USER=root
    export HOME=~root

    rm -f /etc/nix/nix.conf
    rm -f /etc/bashrc
    ln -s /etc/static/bashrc /etc/bashrc
    . /etc/static/bashrc
    cat /Volumes/CONFIG/darwin-configuration.nix | sudo -u nixos -- tee ~nixos/.nixpkgs/darwin-configuration.nix

    while ! sudo -i -H -u nixos -- nix ping-store; do
        cat /var/log/nix-daemon.log
        sleep 1
    done

    sudo -i -H -u nixos -- darwin-rebuild switch
)

