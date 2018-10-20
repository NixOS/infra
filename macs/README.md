# MacOS Infrastructure

Contained are Nix expression for deploying the hydra.nixos.org macOS
infrastructure. Each computer is genuine Apple hardware running NixOS
on the host, with macOS using almost all of the host's resources in an
immutable QEMU virtual machine.

The virtualisation of macOS seems to be a less error-prone, and easier
to recover from problems.


## Bootstrapping a new mac

### Initial Setup

We distribute the macOS image with `zfs send` / `zfs receive`. First
enable ZFS in the installation environment.

1. Add `boot.supportedFilesystems = [ "zfs" ];` to
   `/etc/nixos/configuration.nix`
2. Run `nixos-rebuild switch`
3. `modprobe zfs`

### Partitioning, Formatting, Mounting

1. Partition the disk:

```
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 512MiB -16GiB
parted /dev/sda -- mkpart primary linux-swap -16GiB -1MiB
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 3 boot on
```

2. Create a zpool with `/dev/sda` and mount it:
```
zpool create -o ashift=12 -o altroot=/mnt rpool /dev/sda1
zfs create -o mountpoint=legacy rpool/root
mount -t zfs rpool/root/nixos /mnt
```
_note: ashift=12 is copypasta, maybe somebody knows better_

3. Create the EFI System Partition and mount it:

```
mkfs.fat -F 32 -n boot /dev/sda3
mkdir /mnt/boot
mount /dev/sda3 /mnt/boot
```

4. Create and enable swap:

```
mkswap -L swap /dev/sda2
swapon /dev/sda2
```

### Generate Configuration

1. Generate the config

```
nixos-generate-config --root /mnt
```

2. Generate a host ID with `head -c 8 /etc/machine-id` , we'll refer
   to it soon.

3. Edit `/mnt/etc/nixos/hardware-configuration.nix` and:

  - change the `/boot` fs device to `/dev/disk/by-label/boot`
  - change the `swap` device to `/dev/disk/by-label/swap`
  - delete the `cpuFreqGovernor` line
  - add `boot.supportedFilesystems = [ "zfs" ];`
  - add `networking.hostId = "the-host-id-you-generated";`
  - add `nixpkgs.config.allowUnfree = true;` if the `broadcom-sta`
    kernel module is enabled.

### Install

Run `nixos-install` and reboot.

### Addition to the NixOps Network

calculate your own `-smp` line like this:

 - cores: # of cores per socket
 - threads: # of threads per core, ie: hyperthreading? set to 2, none? set to 1
 - sockets: # of physical sockets in the system
 - cpus = * cores * threads * sockets
