# Deploying to darwin

See [inventory](../docs/inventory.md).

## At Graham's place

We have mac-mini's are in [Grahams](https://github.com/grahamc) house,
that only [@cole-h](https://github.com/cole-h) can deploy:

- becoming-hyena.foundation.detsys.dev
- cosmic-stud.foundation.detsys.dev
- quality-ram.foundation.detsys.dev
- tight-bug.foundation.detsys.dev

- These are getting erased and automatically redeployed from the configuration in this directory.

## Hetzner

Additional we have five M1 builders at Hetzner online:

- enormous-catfish.mac.nixos.org
- growing-jennet.mac.nixos.org
- intense-heron.mac.nixos.org
- maximum-snail.mac.nixos.org
- sweeping-filly.mac.nixos.org

These are maintained by the build infra team.

### Install

- Login to user hetzner with the given password
- Set up SSH keys in the hetzner user
- Elevate with `sudo su`
- ~~Install latest system updates~~
  - ~~softwareupdate --install --all --restart~~
- Disable auto-updates:
  - We are currently seeing performance regression in macOS Sequoia.
  - So to not have the machines auto-upgrade, we use: `sudo softwareupdate --schedule off`
- Install rosetta2
  - softwareupdate --install-rosetta2 --agree-to-license
- Set up passwordless sudo
  ```
  # visudo /etc/sudoers.d/passwordless
  %admin ALL = NOPASSWD: ALL
  ````
- Install nix
  - `sh <(curl -L https://nixos.org/nix/install) --daemon`
- Install nix-darwin
  - `nix --extra-experimental-features 'flakes nix-command' run nix-darwin -- switch --flake github:nixos/infra#arm64`
  - `darwin-rebuild` becomes available after restarting the shell

### Update

```
darwin-rebuild switch --flake github:nixos/infra#arm64
```

