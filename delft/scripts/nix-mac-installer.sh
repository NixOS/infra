#! /usr/bin/env bash

set -e

if [[ $(id -u) != 0 ]]; then
    echo "$0: please run this script as root"
    exit 1
fi

export HOME=/var/root

if ! dscl . read /Groups/nixbld > /dev/null 2>&1; then
    dseditgroup -o create nixbld -q
fi

gid=$(dscl . -read /Groups/nixbld | awk '($1 == "PrimaryGroupID:") {print $2 }')

echo "created nixbld group with gid $gid"

for i in $(seq 1 10); do
    user=/Users/nixbld$i
    uid="$((30000 + $i))"
    dscl . -create $user
    dscl . -create $user RealName "Nix build user $i"
    dscl . -create $user PrimaryGroupID "$gid"
    dscl . -create $user UserShell /usr/bin/false
    dscl . -create $user NFSHomeDirectory /var/empty
    dscl . -create $user UniqueID "$uid"
    dseditgroup -o edit -a nixbld$i -t user nixbld
    echo "created nixbld$i user with uid $uid"
done

curl https://nixos.org/nix/install | sh

mkdir -p /etc/nix
echo "pre-build-hook = " > /etc/nix/nix.conf

mkdir -p /var/root/.ssh
touch /var/root/.ssh/authorized_keys
grep -v "buildfarm@nixos" /var/root/.ssh/authorized_keys > /var/root/.ssh/authorized_keys.tmp || true
echo 'command="TMPDIR=/var/tmp SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /nix/var/nix/profiles/default/bin/nix-store --serve --write" ssh-dss AAAAB3NzaC1kc3MAAACBAMHRjGSDaBp4Z30JF4S9ApabBCpdr57Ad0aD9oH2A/WEFnWYQSAzK4E/HHD2DV2XP1stNkZ1ks2v3F4Yu/veR+qVlUWbJW1RIIfuQgkG44K0R3C2qx4BAZUVYzju1NVCJbBOO6ipVY9cfmpokV52HZFhP/2HocTNLoav3F0AsbbJAAAAFQDaJiQdpJBEa4Wr5FfVl1kYqmQZJwAAAIEAwbern5XL+SNIMa+sJ3CBhrWyYExYWiUbdmhQEfyEAUmoPsEr1qpb+0WREic9Nrxz48QWZDK5xMvzZyQEkuAMJUBWcdm12rME7WMvg7OZGr9DADjAtfMfj3Ui2XvOuQ3ia/OTsMGkQTDWnkOM9Ni128SNSl9urFBlXATdGvo+468AAACBAK8s6LddhhkRqsF/l/L2ooS8c8A1rTFWAOy3/sgXFNvMyS/Mig2p966xRrRHr7Bc+H2SuKEE5WmLCXqymgxLHhrFU4zm/W/ej1yB1CAThd4xUfgJu4touJROjvcD1zzlmLeat0fp2k5mCuiLKcTKi0vxKWiiopF9nvBBK+7ODPC7 buildfarm@nixos' >> /var/root/.ssh/authorized_keys.tmp
mv /var/root/.ssh/authorized_keys.tmp /var/root/.ssh/authorized_keys

service_plist=/Library/LaunchDaemons/org.nixos.nix-daemon.plist

ln -sfn /nix/var/nix/profiles/default$service_plist $service_plist
launchctl unload $service_plist || true
launchctl load $service_plist
launchctl start $service_plist
