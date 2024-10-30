#! /usr/bin/env bash

set -e

if [[ $(id -u) != 0 ]]; then
  echo "$0: please run this script as root"
  exit 1
fi

export HOME=/var/root

if ! dscl . read /Groups/nixbld >/dev/null 2>&1; then
  dseditgroup -o create nixbld -q
fi

gid=$(dscl . -read /Groups/nixbld | awk '($1 == "PrimaryGroupID:") {print $2 }')

echo "created nixbld group with gid $gid"

for i in $(seq 1 10); do
  user=/Users/nixbld$i
  uid="$((30000 + i))"
  dscl . -create "$user"
  dscl . -create "$user" RealName "Nix build user $i"
  dscl . -create "$user" PrimaryGroupID "$gid"
  dscl . -create "$user" UserShell /usr/bin/false
  dscl . -create "$user" NFSHomeDirectory /var/empty
  dscl . -create "$user" UniqueID "$uid"
  dseditgroup -o edit -a "nixbld$i" -t user nixbld
  echo "created nixbld$i user with uid $uid"
done

curl https://nixos.org/nix/install | sh

mkdir -p /var/root/.ssh
touch /var/root/.ssh/authorized_keys
grep -v "hydra-queue-runner@chef" /var/root/.ssh/authorized_keys >/var/root/.ssh/authorized_keys.tmp || true
echo 'command="/nix/var/nix/profiles/default/bin/nix-store --serve --write" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyM48VC5fpjJssLI8uolFscP4/iEoMHfkPoT9R3iE3OEjadmwa1XCAiXUoa7HSshw79SgPKF2KbGBPEVCascdAcErZKGHeHUzxj7v3IsNjObouUOBbJfpN4DR7RQT28PZRsh3TvTWjWnA9vIrSY/BvAK1uezFRuObvatqAPMrw4c0DK+JuGuCNkKDGHLXNSxYBc5Pmr1oSU7/BDiHVjjyLIsAMIc20+q8SjWswKqL1mY193mN7FpUMBtZrd0Za9fMFRII9AofEIDTOayvOZM6+/1dwRWZXM6jhE6kaPPF++yromHvDPBnd6FfwODKLvSF9BkA3pO5CqrD8zs7ETmrV hydra-queue-runner@chef' >>/var/root/.ssh/authorized_keys.tmp
mv /var/root/.ssh/authorized_keys.tmp /var/root/.ssh/authorized_keys

service_plist=/Library/LaunchDaemons/org.nixos.nix-daemon.plist

ln -sfn /nix/var/nix/profiles/default$service_plist $service_plist
launchctl unload $service_plist || true
launchctl load $service_plist
launchctl start $service_plist
