# Deploying to darwin

See [inventory](../docs/inventory.md).

## Inventory

### Obisdian Systems (US Hosting)

They are hosting five Macs Minis for us in the United States.

Contact: [@ryantrinkle](https://github.com/ryantrinkle)

- Mac Mini (M1 2020, 16 GB, 256 GB)
- Mac Mini (M1 2020, 16 GB, 256 GB)
- Mac Mini (M1 2020, 16 GB, 256 GB)
- Mac Mini (M1 2020, 16 GB, 256 GB)
- Mac Mini (i3-8100B, 8GB, 128 GB)

### Flying Circus (DE Hosting)

Currently hosting two Mac Minis for us in Germany.

Contact: [@ctheune](https://github.com/ctheune)

- Mac Mini (M1 2020, 16 GB, 256 GB)
- Mac Mini (M1 2020, 16 GB, 256 GB)

### Hetzner

Additional we rent five M1 (16 GB, 256 GB) builders at Hetzner online:

- enormous-catfish.mac.nixos.org
- growing-jennet.mac.nixos.org
- intense-heron.mac.nixos.org
- maximum-snail.mac.nixos.org
- sweeping-filly.mac.nixos.org

These are maintained by the build infra team.

### Oakhost

Two M2 Mac Mini with 24 GB RAM and 1 TB disk are sponsored by
[Oakhost](https://www.oakhost.com/).

If you are looking for Mac Hosting in the EU, we can recommend Oakhost. They
offer a great admin experience with ad-hoc KVM access in the browser.

- eager-heisenberg.mac.nixos.org
- kind-lumiere.mac.nixos.org

## Install

- Login to user hetzner with the given password
- Set up SSH keys in the hetzner user
- Elevate with `sudo su`
- ~~Install latest system updates~~
  - ~~softwareupdate --install --all --restart~~
- Disable auto-updates:
  - We are currently seeing performance regression in macOS Sequoia.
  - So to not have the machines auto-upgrade, we use:
    `sudo softwareupdate --schedule off`
- Install rosetta2
  - softwareupdate --install-rosetta2 --agree-to-license
- Set up passwordless sudo
  ```
  # visudo /etc/sudoers.d/passwordless
  %admin ALL = NOPASSWD: ALL
  ```
- Install nix
  - `sh <(curl -L https://nixos.org/nix/install) --daemon`
- Install nix-darwin
  - `nix --extra-experimental-features 'flakes nix-command' run nix-darwin -- switch --flake github:nixos/infra#arm64`
  - `darwin-rebuild` becomes available after restarting the shell

## Update

```
darwin-rebuild switch --flake github:nixos/infra#arm64
```
