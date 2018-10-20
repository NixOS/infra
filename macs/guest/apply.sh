#!/usr/bin/env bash

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
    curl https://nixos.org/releases/nix/nix-2.1.3/install > ~nixos/install-nix
    chmod +rwx ~nixos/install-nix
    cat /dev/null | sudo -i -H -u nixos -- sh ~nixos/install-nix --daemon
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
    nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
    nix-channel --update

    sudo -i -H -u nixos -- nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
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
    sudo -i -H -u nixos -- darwin-rebuild switch
)
