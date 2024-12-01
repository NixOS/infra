# Setup

## Switch to UEFI

First submit a support ticket asking them to enable UEFI. See:
https://docs.hetzner.com/robot/dedicated-server/operating-systems/uefi/

# Correct the NVMe namespace's block size

Verify the NVMe disks are formatted at the namespace level with 4096 blocks. See
https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Hardware.html#nvme-low-level-formatting

This disk's LBA is 512:

```console
root@rescue ~ # smartctl -a /dev/nvme1n1
smartctl 7.2 2020-12-30 r5155 [x86_64-linux-5.16.5] (local build)
Copyright (C) 2002-20, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Number:                       SAMSUNG MZQL23T8HCLS-00A07
Serial Number:                      S64HNE0T226681
Firmware Version:                   GDC5602Q
PCI Vendor/Subsystem ID:            0x144d
IEEE OUI Identifier:                0x002538
Total NVM Capacity:                 3,840,755,982,336 [3.84 TB]
Unallocated NVM Capacity:           0
Controller ID:                      6
NVMe Version:                       1.4
Number of Namespaces:               32
Namespace 1 Size/Capacity:          3,840,755,982,336 [3.84 TB]
Namespace 1 Utilization:            4,309,307,392 [4.30 GB]
Namespace 1 Formatted LBA Size:     512
Local Time is:                      Wed Mar 30 03:28:16 2022 CEST
Firmware Updates (0x17):            3 Slots, Slot 1 R/O, no Reset required
Optional Admin Commands (0x005f):   Security Format Frmw_DL NS_Mngmt Self_Test MI_Snd/Rec
Optional NVM Commands (0x005f):     Comp Wr_Unc DS_Mngmt Wr_Zero Sav/Sel_Feat Timestmp
Log Page Attributes (0x0e):         Cmd_Eff_Lg Ext_Get_Lg Telmtry_Lg
Maximum Data Transfer Size:         512 Pages
Warning  Comp. Temp. Threshold:     80 Celsius
Critical Comp. Temp. Threshold:     83 Celsius
Namespace 1 Features (0x1a):        NA_Fields No_ID_Reuse NP_Fields

Supported Power States
St Op     Max   Active     Idle   RL RT WL WT  Ent_Lat  Ex_Lat
 0 +    25.00W   14.00W       -    0  0  0  0       70      70
 1 +     8.00W    8.00W       -    1  1  1  1       70      70

Supported LBA Sizes (NSID 0x1)
Id Fmt  Data  Metadt  Rel_Perf
 0 +     512       0         0
 1 -    4096       0         0

=== START OF SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

SMART/Health Information (NVMe Log 0x02)
Critical Warning:                   0x00
Temperature:                        43 Celsius
Available Spare:                    100%
Available Spare Threshold:          10%
Percentage Used:                    0%
Data Units Read:                    187 [95.7 MB]
Data Units Written:                 8,423 [4.31 GB]
Host Read Commands:                 2,591
Host Write Commands:                3,438
Controller Busy Time:               0
Power Cycles:                       5
Power On Hours:                     203
Unsafe Shutdowns:                   0
Media and Data Integrity Errors:    0
Error Information Log Entries:      0
Warning  Comp. Temperature Time:    0
Critical Comp. Temperature Time:    0
Temperature Sensor 1:               43 Celsius
Temperature Sensor 2:               53 Celsius

Error Information (NVMe Log 0x01, 16 of 64 entries)
No Errors Logged
```

and correctable with:

```sh
nvme format /dev/nvme0n1 -l 1
```

which yields a corrected formatting:

```console
root@rescue ~ # smartctl -a /dev/nvme1n1
smartctl 7.2 2020-12-30 r5155 [x86_64-linux-5.16.5] (local build)
Copyright (C) 2002-20, Bruce Allen, Christian Franke, www.smartmontools.org

=== START OF INFORMATION SECTION ===
Model Number:                       SAMSUNG MZQL23T8HCLS-00A07
Serial Number:                      S64HNE0T226681
Firmware Version:                   GDC5602Q
PCI Vendor/Subsystem ID:            0x144d
IEEE OUI Identifier:                0x002538
Total NVM Capacity:                 3,840,755,982,336 [3.84 TB]
Unallocated NVM Capacity:           0
Controller ID:                      6
NVMe Version:                       1.4
Number of Namespaces:               32
Namespace 1 Size/Capacity:          3,840,755,982,336 [3.84 TB]
Namespace 1 Utilization:            4,309,307,392 [4.30 GB]
Namespace 1 Formatted LBA Size:     512
Local Time is:                      Wed Mar 30 03:29:46 2022 CEST
Firmware Updates (0x17):            3 Slots, Slot 1 R/O, no Reset required
Optional Admin Commands (0x005f):   Security Format Frmw_DL NS_Mngmt Self_Test MI_Snd/Rec
Optional NVM Commands (0x005f):     Comp Wr_Unc DS_Mngmt Wr_Zero Sav/Sel_Feat Timestmp
Log Page Attributes (0x0e):         Cmd_Eff_Lg Ext_Get_Lg Telmtry_Lg
Maximum Data Transfer Size:         512 Pages
Warning  Comp. Temp. Threshold:     80 Celsius
Critical Comp. Temp. Threshold:     83 Celsius
Namespace 1 Features (0x1a):        NA_Fields No_ID_Reuse NP_Fields

Supported Power States
St Op     Max   Active     Idle   RL RT WL WT  Ent_Lat  Ex_Lat
 0 +    25.00W   14.00W       -    0  0  0  0       70      70
 1 +     8.00W    8.00W       -    1  1  1  1       70      70

Supported LBA Sizes (NSID 0x1)
Id Fmt  Data  Metadt  Rel_Perf
 0 +     512       0         0
 1 -    4096       0         0

=== START OF SMART DATA SECTION ===
SMART overall-health self-assessment test result: PASSED

SMART/Health Information (NVMe Log 0x02)
Critical Warning:                   0x00
Temperature:                        43 Celsius
Available Spare:                    100%
Available Spare Threshold:          10%
Percentage Used:                    0%
Data Units Read:                    187 [95.7 MB]
Data Units Written:                 8,423 [4.31 GB]
Host Read Commands:                 2,591
Host Write Commands:                3,438
Controller Busy Time:               0
Power Cycles:                       5
Power On Hours:                     203
Unsafe Shutdowns:                   0
Media and Data Integrity Errors:    0
Error Information Log Entries:      0
Warning  Comp. Temperature Time:    0
Critical Comp. Temperature Time:    0
Temperature Sensor 1:               43 Celsius
Temperature Sensor 2:               53 Celsius

Error Information (NVMe Log 0x01, 16 of 64 entries)
No Errors Logged
```

We can now use an ashift of 12 (2^12 = 4096) without a performance penalty.

## Partitioning

The following script can be, and was run fully automatically:

```sh
set -eux

if ! [ -e /usr/local/sbin/zfs ]; then
echo "installing zfs..."
bash -i -c 'echo y | zfsonlinux_install'
fi

umount -R /mnt || true

zpool destroy rpool || true


for disk in /dev/nvme0n1 /dev/nvme1n1; do
echo "partitioning $disk..."
index="${disk: -3:1}"
parted -s $disk "mklabel gpt"
parted -a optimal -s $disk "mkpart primary fat32 1m 512m"
parted -a optimal -s $disk "mkpart primary zfs 512m 100%"
parted -s $disk "set 1 esp on"
udevadm settle
mkfs.vfat -n BOOT$index ''${disk}p1
done

zpool create -f -o ashift=12 -o autotrim=on \
-O mountpoint=legacy -O atime=off -O compression=on \
rpool mirror /dev/nvme0n1p2 /dev/nvme1n1p2

zfs create rpool/local
zfs create rpool/local/nix
zfs create -o recordsize=4k rpool/local/nix/db
zfs create -o xattr=sa -o acltype=posix rpool/local/var
zfs create rpool/safe
zfs create rpool/safe/root

mkdir -p /mnt
mount -t zfs rpool/safe/root /mnt

mkdir -p /mnt/nix
mount -t zfs rpool/local/nix /mnt/nix

mkdir -p /mnt/nix/var/nix/db
mount -t zfs rpool/local/nix/db /mnt/nix/var/nix/db

mkdir -p /mnt/var
mount -t zfs rpool/local/var /mnt/var

mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT0 /mnt/boot
```

## Installing Nix

Install Nix into the rescue system as root:

```sh
groupadd -g 30000 nixbld
useradd --system --groups nixbld nixbld1
useradd --system --groups nixbld nixbld2
useradd --system --groups nixbld nixbld3
useradd --system --groups nixbld nixbld4
useradd --system --groups nixbld nixbld5
mkdir -m 0755 /nix && chown root /nix
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

## Configure NixOS

```sh
nix-shell -p nixos-install-tools -I nixpkgs=channel:nixos-21.11

nixos-generate-config --root /mnt
```

In the `configuration.nix`:

1. Add `hetzner.nix` to the list of `imports` at the top.
2. Add an authorized key and enable SSH. This will be removed later when it is
   imported into NixOps, so it is just for bootstrapping:

```
services.openssh.enable = true;
users.users.root.openssh.authorizedKeys.keys = [ "ssh-..." ];
```

### Hardware Configuration Changes

Edit `hardware-configuration.nix` and change the fileSystems value for
`/nix/var/nix` to make it required for boot:

```nix
fileSystems."/nix/var/nix/db" =
  { device = "rpool/local/nix/db";
    fsType = "zfs";
    neededForBoot = true;
  };
```

### Hetzner.nix

Then create a file, `hetzner.nix`.

- The all-zeros hostId is fine, though I generated one with
  `head -c4 /dev/urandom | od -A none -t x4`
- The `enp7s0` and `MACAddress` value I got from `ip addr`
- The IP addresses and gateways I got from the Robot webpage under the IPs tab,
  hovering over the IPv4 and IPv6 addresses.
- Thee DNS resolvers I got from
  https://docs.hetzner.com/dns-console/dns/general/recursive-name-servers/

```nix
{
  networking.hostId = "00000000";
  networking.useNetworkd = true;
  systemd.network.networks."40-enp7s0" = {
    matchConfig.MACAddress = "50:eb:f6:22:f0:3a";

    addresses = [
      {
        addressConfig.Address = "5.9.122.43/27";
      }
      {
        addressConfig.Address = "2a01:4f8:162:71eb::/64";
      }
    ];
    routes = [
      {
        routeConfig.Gateway = "5.9.122.33";
      }
      {
        routeConfig.Gateway = "fe80::1";
      }
    ];

    dns = [
      "185.12.64.1"
      "185.12.64.2"
      "2a01:4ff:ff00::add:1"
      "2a01:4ff:ff00::add:2"
    ];
  };
}
```

Then run:

```
nixos-install -I nixpkgs=channel:nixos-21.11
```
